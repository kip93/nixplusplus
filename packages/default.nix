{ self, ... } @ inputs:
builtins.listToAttrs
  (builtins.map
    (system: {
      name = system;
      value = builtins.listToAttrs
        (builtins.filter
          (package: package.value != null)
          (builtins.map
            (name:
              let
                drv = (import "${./.}/${name}" (inputs // { inherit system; })).overrideAttrs (super: {
                  meta = super.meta // {
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
              in
              {
                inherit name;
                value =
                  if (!drv.meta ? platforms) || (builtins.any (p: p == system) drv.meta.platforms) then
                    drv
                  else
                    null
                ;
              })
            (builtins.filter
              (name: builtins.pathExists "${./.}/${name}/default.nix")
              (builtins.attrNames (builtins.readDir ./.))
            )
          )
        );
    })
    self.lib.nixplusplus.supportedSystems
  )
