{ self, ... } @ inputs:
let
  inherit (self) lib;
  inherit (lib) recursiveUpdate;
  importAsAttrs' = lib.nixplusplus.import.asAttrs';

in
importAsAttrs' {
  path = ./.;
  apply = name: module: { config, ... }: {
    imports = [ (module inputs) ];
    meta = {
      inherit (lib.nixplusplus.meta) maintainers;
      doc = config.nixplusplus.${name}.meta.doc or null;
    };
  };
}
