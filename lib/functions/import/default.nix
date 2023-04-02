{ self, ... } @ inputs:
rec {
  # Locate importable paths in a directory.
  locate = path:
    builtins.map
      (name: (path + "/${name}"))
      (builtins.filter
        (name: builtins.pathExists (path + "/${name}/default.nix"))
        (builtins.attrNames (builtins.readDir path))
      )
  ;

  # Locate importable paths in a directory, and import them into a list.
  asList = path: asList' { inherit path; };
  asList' = { path, func ? self.lib.id, system ? null }:
    builtins.filter
      (x:
        (system == null)
        || (!self.lib.hasAttrByPath [ "meta" "platforms" ] x)
        || (builtins.any (p: p == system) x.meta.platforms)
      )
      (builtins.map import (locate path))
  ;

  # Locate importable paths in a directory, and import them into an attribute set.
  asAttrs = path: asAttrs' { inherit path; };
  asAttrs' = { path, func ? self.lib.id, system ? null }:
    builtins.listToAttrs
      (builtins.filter
        (x:
          (system == null)
          || (!self.lib.hasAttrByPath [ "meta" "platforms" ] x.value)
          || (builtins.any (p: p == system) x.value.meta.platforms)
        )
        (builtins.map
          (path': {
            name = builtins.baseNameOf path';
            value = func (import path');
          })
          (locate path)
        )
      )
  ;
}
