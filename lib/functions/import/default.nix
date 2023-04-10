{ self, ... } @ inputs:
let
  # The use of `unsafeDiscardStringContext` is a technicality, since if the path
  # is on the nix store the basename will remember that. This breaks the
  # expression since nix does not like an attrset key w/ a nix store path, so we
  # explictly tell it to discard that. This is safe since the store path is
  # still being used in the value of the attrset entry, so we don't have any
  # issues where the store path might be missing.
  getName = path:
    builtins.unsafeDiscardStringContext
      (builtins.baseNameOf path)
  ;

in
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
  asList' = { path, apply ? (_: self.lib.id), system ? null }:
    builtins.filter
      (x:
        (system == null)
        || (!self.lib.hasAttrByPath [ "meta" "platforms" ] x)
        || (builtins.any (p: p == system) x.meta.platforms)
      )
      (builtins.map
        (path': apply (getName path') (import path'))
        (locate path)
      )
  ;

  # Locate importable paths in a directory, and import them into an attribute set.
  asAttrs = path: asAttrs' { inherit path; };
  asAttrs' = { path, apply ? (_: self.lib.id), system ? null }:
    builtins.listToAttrs
      (builtins.filter
        (x:
          (system == null)
          || (!self.lib.hasAttrByPath [ "meta" "platforms" ] x.value)
          || (builtins.any (p: p == system) x.value.meta.platforms)
        )
        (builtins.map
          (path': rec {
            name = getName path';
            value = apply name (import path');
          })
          (locate path)
        )
      )
  ;
}
