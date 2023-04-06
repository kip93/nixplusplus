{ self, ... } @ inputs:
let
  args = localSystem: crossSystem: inputs // {
    inherit (self.lib.nixplusplus.pkgs.${localSystem}.${crossSystem}) pkgs;
    inherit localSystem crossSystem;
  };
  mapSystems = mapFunction:
    builtins.listToAttrs
      (builtins.map
        mapFunction
        self.lib.nixplusplus.supportedSystems
      )
  ;
  patchMeta = super: {
    meta = super.meta // {
      homepage = "ssh://git.kip93.net/nix++";
      maintainers = [{
        name = "Leandro Emmanuel Reina Kiperman";
        email = "leandro@kip93.net";
        github = "kip93";
      }];
      license = with self.lib.licenses; super.meta.license or [ gpl3 ];
    };
  };

  packages = mapSystems (localSystem: {
    name = localSystem;
    value = mapSystems (crossSystem: {
      name = crossSystem;
      value = (self.lib.nixplusplus.pkgs.${localSystem}.${crossSystem}.linkFarm
        "${crossSystem}_package-set"
        (self.lib.nixplusplus.import.asAttrs' {
          path = ./.;
          system = crossSystem;
          func = pkg:
            (pkg (args localSystem crossSystem)).overrideAttrs patchMeta
          ;
        })
      ).overrideAttrs (super: { passthru = super.passthru.entries; });
    });
  });

in
self.lib.recursiveUpdate
  packages
  (mapSystems (system: {
    name = system;
    value = packages.${system}.${system}.passthru;
  }))
