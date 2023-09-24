# This file is part of Nix++.
# Copyright (C) 2023 Leandro Emmanuel Reina Kiperman.
#
# Nix++ is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# Nix++ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

{ devenv, nixpkgs, self, ... } @ _inputs:
let
  # The use of `unsafeDiscardStringContext` is a technicality, since if the path
  # is on the nix store the basename will remember that. This breaks the
  # expression since nix does not like an attrset key w/ a nix store path, so we
  # explictly tell it to discard that. This is safe since the store path is
  # still being used in the value of the attrset entry, so we don't have any
  # issues where the store path might be missing.
  getName = path:
    builtins.unsafeDiscardStringContext
      (builtins.baseNameOf path)
  ;

in
rec {
  # Locate importable paths in a directory.
  locate = path:
    builtins.map
      (name: (path + "/${name}"))
      (builtins.filter
        (name: builtins.pathExists (path + "/${name}/default.nix"))
        (builtins.attrNames (builtins.readDir path))
      )
  ;

  # Locate importable paths in a directory, and import them into a list.
  asList = path: asList' { inherit path; };
  asList' = { path, apply ? (_: x: x), system ? null }:
    builtins.filter
      (element:
        (system == null) || (self.lib.isSupported element system)
      )
      (builtins.map
        (path': apply (getName path') (import path'))
        (locate path)
      )
  ;

  # Locate importable paths in a directory, and import them into an attribute
  # set.
  asAttrs = path: asAttrs' { inherit path; };
  asAttrs' = { path, apply ? (_: x: x), system ? null }:
    builtins.listToAttrs
      (builtins.filter
        (entry:
          (system == null) || (self.lib.isSupported entry.value system)
        )
        (builtins.map
          (path': rec {
            name = getName path';
            value = apply name (import path');
          })
          (locate path)
        )
      )
  ;

  # Locate importable paths in a directory, and import them as apps.
  asApps = path: asApps' { inherit path; };
  asApps' = { path, apply ? (_: _: x: x) }:
    self.lib.forEachSupportedSystem (system: asAttrs' {
      inherit path system;
      apply = name: app:
        let
          drv = apply name system app;

        in
        {
          type = "app";
          program = "${drv}${drv.passthru.exePath or "/bin/${drv.pname or drv.name}"}";
        }
      ;
    })
  ;

  # Locate importable paths in a directory, and import them as checks.
  asChecks = path: asChecks' { inherit path; };
  asChecks' = { path, apply ? (_: _: x: x) }:
    self.lib.forEachSupportedSystem (system: asAttrs' {
      inherit path system;
      apply = name: apply name system;
    })
  ;

  # Locate importable paths in a directory, and import them as dev shells.
  asShells = path: asShells' { inherit path; };
  asShells' = { path, apply ? (_: _: x: x) }:
    self.lib.forEachSupportedSystem (system: asAttrs' {
      inherit path system;
      apply = name: shell:
        devenv.lib.mkShell (apply name system shell)
      ;
    })
  ;

  # Locate importable paths in a directory, and import them as NixOS
  # configurations.
  asConfigs = path: asConfigs' { inherit path; };
  asConfigs' = { path, apply ? (_: x: x) }:
    builtins.mapAttrs
      (_: config: import "${nixpkgs}/nixos/lib/eval-config.nix" {
        system = null;
        specialArgs = self.lib.flakes.registry;
        modules = [
          self.nixosModules.default
          config
        ];
      })
      (asAttrs' { inherit apply path; })
  ;
  # Import a single configuration.
  asConfig = path: asConfig' { inherit path; };
  asConfig' = { path, apply ? (_: x: x) }:
    import "${nixpkgs}/nixos/lib/eval-config.nix" {
      system = null;
      specialArgs = self.lib.flakes.registry;
      modules = [
        self.nixosModules.default
        (apply (getName path) (import path))
      ];
    }
  ;

  # Locate importable paths in a directory, and import them as a library.
  asLib = path: asLib' { inherit path; };
  asLib' = { path, apply ? (_: x: x) }:
    builtins.foldl'
      nixpkgs.lib.recursiveUpdate
      { }
      (asList' { inherit apply path; })
  ;

  # Locate importable paths in a directory, and import them as modules.
  asModules = path: asModules' { inherit path; };
  asModules' = { path, apply ? (_: x: x) }:
    asAttrs' { inherit apply path; }
  ;

  # Locate importable paths in a directory, and import them as overlays.
  asOverlays = path: asOverlays' { inherit path; };
  asOverlays' = { path, apply ? (_: x: x) }:
    let
      overlays = asAttrs' { inherit apply path; };
    in
    if overlays ? default then
      overlays
    else
      overlays // {
        default = final: prev:
          builtins.foldl'
            (x: y: x // (y final (prev // x)))
            { }
            (builtins.attrValues overlays)
        ;
      }
  ;

  # Locate importable paths in a directory, and import them as packages.
  asPackages = path: asPackages' { inherit path; };
  asPackages' = { path, apply ? (_: _: _: x: x) }:
    let
      packages = self.lib.forEachSupportedSystem' (localSystem: crossSystem:
        (self.lib.pkgs.${localSystem}.${crossSystem}.linkFarm
          "${crossSystem}-meta-package"
          (asAttrs' {
            inherit path;
            system = crossSystem;
            apply = name: apply name localSystem crossSystem;
          })
        ).overrideAttrs (super: {
          passthru = super.passthru.entries // rec {
            _all = self.lib.pkgs.${localSystem}.${crossSystem}.linkFarm
              "all-packages-meta-package"
              super.passthru.entries
            ;
            ${if !(super.passthru.entries ? default) then "default" else null} = _all;
          };
        })
      );

    in
    nixpkgs.lib.recursiveUpdate
      packages
      (self.lib.forEachSupportedSystem (system:
        packages.${system}.${system}.passthru
      ))
  ;

  # Locate importable paths in a directory, and import them as schemas.
  asSchemas = path: asSchemas' { inherit path; };
  asSchemas' = { path, apply ? (_: x: x) }:
    asAttrs' { inherit apply path; }
  ;

  # Locate importable paths in a directory, and import them as templates.
  asTemplates = path: asTemplates' { inherit path; };
  asTemplates' = { path, apply ? (_: x: x) }:
    asAttrs' { inherit apply path; }
  ;

  # This one is a bit different. Usually when it comes to NixOS configurations,
  # these flakes only ever contain a sinle configuration and nothing else; and
  # so with that assumption in mind I can do a hacky config cross compilation
  # setup, by having also package settings alongside with a somewhat simplified
  # structure (one fewer depth level).
  asCrossConfig = path: asCrossConfig' { inherit path; };
  asCrossConfig' = { path, apply ? (_: x: x) }:
    let
      buildConfig = module: import "${nixpkgs}/nixos/lib/eval-config.nix" {
        system = null;
        specialArgs = self.lib.flakes.registry;
        modules = [
          # Have a default system, for when not building via the packages below
          { nixpkgs.localSystem = self.lib.mkDefault "x86_64-linux"; }
          self.nixosModules.default
          module
        ];
      };
      baseConfig = apply (getName path) (import path);

    in
    {
      nixosConfigurations =
        let
          nativeConfig = buildConfig baseConfig;
          inherit (nativeConfig.config.networking) hostName;

        in
        { ${hostName} = nativeConfig; }
      ;

      packages =
        let
          packages = self.lib.forEachSystem' self.lib.supportedSystems'.linux
            (localSystem: crossSystem:
              let
                crossConfig = buildConfig ({ config, lib, ... }: {
                  imports = [ baseConfig ];
                  nixpkgs = {
                    pkgs = self.lib.mkStrict (import nixpkgs {
                      inherit (config.nixpkgs)
                        config
                        overlays
                        ;
                      inherit
                        localSystem
                        crossSystem
                        ;
                    });
                    hostPlatform = self.lib.mkStrict
                      (lib.systems.elaborate crossSystem)
                    ;
                  };
                });

              in
              crossConfig.config.system.build.toplevel.overrideAttrs
                ({ name, ... }: {
                  name = "${name}+${nixpkgs.lib.optionalString
                    (localSystem != crossSystem)
                    "${localSystem}+"
                  }${crossSystem}";
                })
            )
          ;

        in
        nixpkgs.lib.recursiveUpdate
          packages
          (self.lib.forEachSystem self.lib.supportedSystems'.linux (system:
            {
              default = packages.${system}.${system}.overrideAttrs (_: {
                passthru = packages.${system};
              });
            }
          ))
      ;
    }
  ;
}
