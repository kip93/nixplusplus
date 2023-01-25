{ self, ... } @ inputs:
builtins.listToAttrs
  (builtins.map
    (system: {
      name = system;
      value = builtins.listToAttrs
        (builtins.map
          (name: { inherit name; value = import "${./.}/${name}" (inputs // { inherit system; }); })
          (builtins.filter
            (name: builtins.pathExists "${./.}/${name}/default.nix")
            (builtins.attrNames (builtins.readDir ./.))
          )
        );
    })
    self.lib.nixplusplus.supportedSystems
  )
