{ self, ... } @ inputs:
builtins.listToAttrs
  (builtins.map
    (system: {
      name = system;
      value = builtins.listToAttrs
        (builtins.map
          (name: {
            inherit name;
            value = (import "${./.}/${name}" (inputs // { inherit system; })).overrideAttrs (super: {
              meta = self.lib.recursiveUpdate super.meta {
                homepage = "ssh://git.kip93.net/nix++";
                maintainers = [
                  {
                    name = "Leandro Emmanuel Reina Kiperman";
                    email = "leandro@kip93.net";
                    github = "kip93";
                  }
                ];
              };
            });
          })
          (builtins.filter
            (name: builtins.pathExists "${./.}/${name}/default.nix")
            (builtins.attrNames (builtins.readDir ./.))
          )
        );
    })
    self.lib.nixplusplus.supportedSystems
  )
