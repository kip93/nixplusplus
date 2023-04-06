{ self, ... } @ inputs:
let
  packages = builtins.listToAttrs
    (builtins.map
      (localSystem: {
        name = localSystem;
        value = builtins.listToAttrs
          (builtins.map
            (crossSystem: {
              name = crossSystem;
              value = self.lib.nixplusplus.import.asAttrs' {
                path = ./.;
                system = crossSystem;
                func = x:
                  (x (inputs // { inherit localSystem crossSystem; })).overrideAttrs (super: {
                    meta = super.meta // {
                      homepage = "ssh://git.kip93.net/nix++";
                      maintainers = [{
                        name = "Leandro Emmanuel Reina Kiperman";
                        email = "leandro@kip93.net";
                        github = "kip93";
                      }];
                      license = with self.lib.licenses; super.meta.license or [ gpl3 ];
                    };
                  })
                ;
              };
            })
            self.lib.nixplusplus.supportedSystems
          )
        ;
      })
      self.lib.nixplusplus.supportedSystems
    );

in
builtins.mapAttrs
  (localSystem: systems:
  builtins.mapAttrs
    (crossSystem: attrset:
    if self.lib.isDerivation attrset then
      attrset

    else
      (self.lib.nixplusplus.pkgs.${localSystem}.${crossSystem}.linkFarm
        "${crossSystem} package set"
        (
          self.lib.mapAttrsToList
            (name: path: { inherit name path; })
            attrset
        )
      ).overrideAttrs (_: { passthru = attrset; })
    )
    systems
  )
  (self.lib.recursiveUpdate
    packages
    (builtins.listToAttrs
      (builtins.map
        (system: {
          name = system;
          value = packages.${system}.${system};
        })
        self.lib.nixplusplus.supportedSystems
      )
    )
  )
