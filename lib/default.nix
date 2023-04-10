{ nixpkgs, ... } @ inputs:
# Cannot use here the nice `import.asAttrs'` function, since this here
# is where it is made available.
nixpkgs.lib.extend (_: _: {
  nixplusplus = builtins.foldl'
    nixpkgs.lib.recursiveUpdate
    { }
    (builtins.map
      (name: import (./. + "/${name}") inputs)
      (builtins.filter
        (name: builtins.pathExists (./. + "/${name}/default.nix"))
        (builtins.attrNames (builtins.readDir ./.))
      )
    );
})
