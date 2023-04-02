{ ... } @ inputs:
builtins.listToAttrs
  (builtins.map
    (name: { inherit name; value = import (./. + "/${name}") inputs; })
    (builtins.filter
      (name: builtins.pathExists (./. + "/${name}/default.nix"))
      (builtins.attrNames (builtins.readDir ./.))
    )
  )
