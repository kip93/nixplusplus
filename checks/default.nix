{ self, ... } @ inputs:
builtins.listToAttrs
  (builtins.map
    (system: {
      name = system;
      value = builtins.listToAttrs
        (builtins.filter
          (check: check.value != null)
          (builtins.map
            (name:
              let
                drv = import (./. + "/${name}") (inputs // { inherit system; });
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
              (name: builtins.pathExists (./. + "/${name}/default.nix"))
              (builtins.attrNames (builtins.readDir ./.))
            )
          )
        );
    })
    self.lib.nixplusplus.supportedSystems
  )
