builtins.listToAttrs
  (builtins.map
    (name: { inherit name; value = import "${./.}/${name}"; })
    (builtins.filter
      (name: builtins.pathExists "${./.}/${name}/default.nix")
      (builtins.attrNames (builtins.readDir ./.))
    )
  )
