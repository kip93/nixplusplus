# This file is part of Nix++.
# Copyright (C) 2023-2024 Leandro Emmanuel Reina Kiperman.
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

{ pkgs, self, ... } @ _args:
let
  apps = self.lib.import.asApps' {
    path = ./apps;
    apply = _: x: y: y { inherit (self.lib.pkgs.${x}.${x}) pkgs; };
  };
  checks = self.lib.import.asChecks' {
    path = ./checks;
    apply = _: x: y: y { inherit (self.lib.pkgs.${x}.${x}) pkgs; };
  };
  configs = self.lib.import.asConfigs ./configs;
  lib = self.lib.import.asLib ./lib;
  modules = self.lib.import.asModules ./modules;
  overlays = self.lib.import.asOverlays ./overlays;
  overlays-no-default = self.lib.import.asOverlays (builtins.path {
    path = ./overlays;
    filter = path: _:
      path != toString ./overlays/default
    ;
  });
  packages = self.lib.import.asPackages' {
    path = ./packages;
    apply = _: x: y: z: z { inherit (self.lib.pkgs.${x}.${y}) pkgs; };
  };
  templates = self.lib.import.asTemplates ./templates;

in
pkgs.testers.nixTest {
  name = builtins.baseNameOf ./.;
  checks = {
    locate = {
      expr = self.lib.import.locate ./apps;
      expected = [ ./apps/sample-app ];
    };
    locateEmpty = {
      expr = self.lib.import.locate ./.;
      expected = [ ];
    };

    asList = {
      expr = self.lib.import.asList' {
        path = ./apps;
        apply = _: y: y {
          inherit (self.lib.pkgs.x86_64-linux.x86_64-linux) pkgs;
        };
      };
      expected = [
        (import ./apps/sample-app {
          inherit (self.lib.pkgs.x86_64-linux.x86_64-linux) pkgs;
        })
      ];
    };
    asAttrs = {
      expr = self.lib.import.asAttrs' {
        path = ./apps;
        apply = _: y: y {
          inherit (self.lib.pkgs.x86_64-linux.x86_64-linux) pkgs;
        };
      };
      expected = {
        sample-app = import ./apps/sample-app {
          inherit (self.lib.pkgs.x86_64-linux.x86_64-linux) pkgs;
        };
      };
    };

    apps = {
      expr =
        let
          app = apps.x86_64-linux.sample-app;
        in
        app.type == "app"
        &&
        pkgs.lib.hasPrefix "${builtins.storeDir}/" app.program
        &&
        pkgs.lib.hasSuffix "/bin/sample-app" app.program
      ;
      expected = true;
    };
    appsSystems = {
      expr =
        pkgs.lib.lists.subtractLists
          (builtins.attrNames apps)
          self.lib.supportedSystems
      ;
      expected = [ ];
    };

    checks = {
      expr =
        let
          check = checks.x86_64-linux.sample-check;
        in
        check.name == "sample-check"
        &&
        check.type == "derivation"
      ;
      expected = true;
    };
    checksSystems = {
      expr =
        pkgs.lib.lists.subtractLists
          (builtins.attrNames checks)
          self.lib.supportedSystems
      ;
      expected = [ ];
    };

    configs = {
      expr =
        let
          inherit (configs.sample-config) config;
        in
        config.system.build ? toplevel
        &&
        config.nix.registry.nixplusplus.flake == self
        # Check workaround for nix-systems#6
        &&
        (!config.nix.registry ? systems)
      ;
      expected = true;
    };

    lib = {
      expr = lib.sum 1 2;
      expected = 3;
    };

    modules = {
      expr =
        let
          module = modules.sample-module;
        in
        module.config == { foo = "bar"; }
        &&
        module.meta.doc == ./modules/sample-module/README.md
      ;
      expected = true;
    };

    overlays = {
      expr = (pkgs.extend overlays.sample-overlay).foo;
      expected = "bar";
    };
    overlaysDefault = {
      expr = (pkgs.extend overlays.default) ? default;
      expected = true;
    };
    overlaysNoDefault = {
      expr =
        let
          pkgs' = pkgs.extend overlays-no-default.default;
        in
        !(pkgs' ? default)
        &&
        pkgs'.foo == "bar"
      ;
      expected = true;
    };

    packages = {
      expr =
        let
          package = packages.x86_64-linux.x86_64-linux.sample-package;
        in
        package.name == "sample-package"
        &&
        package.type == "derivation"
        &&
        package.system == "x86_64-linux"
      ;
      expected = true;
    };
    packagesCross = {
      expr =
        let
          package = packages.x86_64-linux.aarch64-linux.sample-package;
        in
        package.name == "sample-package"
        &&
        package.type == "derivation"
        &&
        package.stdenv.buildPlatform.system == "x86_64-linux"
        &&
        package.stdenv.targetPlatform.system == "aarch64-linux"
      ;
      expected = true;
    };
    packagesSystems = {
      expr =
        pkgs.lib.lists.subtractLists
          (builtins.attrNames packages)
          self.lib.supportedSystems
      ;
      expected = [ ];
    };
    packagesCrossSystems = {
      expr =
        packages.x86_64-linux ? aarch64-linux
        &&
        !packages.x86_64-linux ? aarch64-darwin
        && # TODO nixpkgs#180771
        !packages.aarch64-darwin ? x86_64-darwin
      ;
      expected = true;
    };

    templates = {
      expr = templates.sample-template;
      expected = {
        path = ./templates/sample-template;
        description = "sample-template";
      };
    };
  };
}
