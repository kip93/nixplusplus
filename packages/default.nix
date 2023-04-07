{ self, ... } @ inputs:
let
  inherit (self) lib;
  inherit (lib.nixplusplus) forEachSystem pkgs;
  importAsAttrs' = lib.nixplusplus.import.asAttrs';

  patchMeta = super: {
    meta = super.meta // {
      homepage = "ssh://git.kip93.net/nix++";
      maintainers = [{
        name = "Leandro Emmanuel Reina Kiperman";
        email = "leandro@kip93.net";
        github = "kip93";
      }];
      license = with lib.licenses; super.meta.license or [ gpl3 ];
    };
  };

  packages = forEachSystem (localSystem: {
    name = localSystem;
    value = forEachSystem (crossSystem: {
      name = crossSystem;
      value = (pkgs.${localSystem}.${crossSystem}.linkFarm
        "${crossSystem}-meta-package"
        (importAsAttrs' {
          path = ./.;
          system = crossSystem;
          func = pkg:
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
              func = pkg:
                pkg (inputs // {
                  inherit (pkgs.${localSystem}.${crossSystem}) pkgs;
                  system = crossSystem;
                })
              ;
            })
          ;
        };
      });
    });
  });

in
lib.recursiveUpdate
  packages
  (forEachSystem (system: {
    name = system;
    value = packages.${system}.${system}.passthru;
  }))
