{ self, ... } @ inputs:
builtins.listToAttrs
  (builtins.map
    (system: {
      name = system;
      value = self.lib.nixplusplus.import.asAttrs' {
        path = ./.;
        func = x:
          (x (inputs // { inherit system; })).overrideAttrs (super: {
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
        inherit system;
      };
    })
    self.lib.nixplusplus.supportedSystems
  )
