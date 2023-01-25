{ nixpkgs, ... } @ inputs:
nixpkgs.lib.extend (_:_: {
  nixplusplus = builtins.foldl'
    (x: y: nixpkgs.lib.recursiveUpdate x y)
    { }
    (builtins.map
      (name: import "${./.}/${name}" inputs)
      (builtins.filter
        (name: builtins.pathExists "${./.}/${name}/default.nix")
        (builtins.attrNames (builtins.readDir ./.))
      )
    );
})
