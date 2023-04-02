{ self, ... } @ inputs:
builtins.listToAttrs
  (builtins.map
    (system: {
      name = system;
      value = self.lib.nixplusplus.import.asAttrs' {
        path = ./.;
        func = x: x (inputs // { inherit system; });
        inherit system;
      };
    })
    self.lib.nixplusplus.supportedSystems
  )
