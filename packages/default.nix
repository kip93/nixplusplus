{ self, ... } @ inputs:
let
  inherit (self) lib;
  inherit (lib.nixplusplus) forEachSystem forEachSystem' pkgs;
  importAsAttrs' = lib.nixplusplus.import.asAttrs';
  meta' = lib.nixplusplus.meta;

  patchMeta = super: {
    meta = super.meta // {
      inherit (meta') homepage maintainers;
      license = super.meta.license or meta'.license;
    };
  };

  packages = forEachSystem' (localSystem: crossSystem:
    (pkgs.${localSystem}.${crossSystem}.linkFarm
        "${crossSystem}-meta-package"
        (importAsAttrs' {
          path = ./.;
          system = crossSystem;
        apply = _: pkg:
            (pkg (inputs // {
              inherit (pkgs.${localSystem}.${crossSystem}) pkgs;
              inherit localSystem crossSystem;
            })).overrideAttrs patchMeta
          ;
        })
      ).overrideAttrs (super: {
        passthru = super.passthru.entries // {
          _all = pkgs.${localSystem}.${crossSystem}.linkFarm
            "all-packages-meta-package"
            super.passthru.entries
          ;
          _apps = pkgs.${localSystem}.${crossSystem}.linkFarm
            "apps-meta-package"
            (importAsAttrs' {
              path = ../apps;
              system = crossSystem;
            apply = _: pkg:
                pkg (inputs // {
                  inherit (pkgs.${localSystem}.${crossSystem}) pkgs;
                  system = crossSystem;
                })
              ;
            })
          ;
        };
    })
  );

in
lib.recursiveUpdate
  packages
  (forEachSystem (system:
  packages.${system}.${system}.passthru
  ))
