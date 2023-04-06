{ nixpkgs, self, ... } @ inputs:
{
  pkgs = builtins.listToAttrs
    (builtins.map
      (localSystem: {
        name = localSystem;
        value = builtins.listToAttrs
          (builtins.map
            (crossSystem: {
              name = crossSystem;
              value = import nixpkgs {
                localSystem.config = nixpkgs.lib.systems.parse.tripleFromSystem (nixpkgs.lib.systems.parse.mkSystemFromString localSystem);
                crossSystem.config = nixpkgs.lib.systems.parse.tripleFromSystem (nixpkgs.lib.systems.parse.mkSystemFromString crossSystem);
              };
            })
            self.lib.nixplusplus.supportedSystems
          )
        ;
      })
      self.lib.nixplusplus.supportedSystems
    )
  ;
}
