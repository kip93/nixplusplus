{ self, ... } @ inputs:
let
  inherit (self) lib;
  inherit (lib) recursiveUpdate;
  inherit (lib.nixplusplus) forEachSystem pkgs;
  importAsAttrs' = lib.nixplusplus.import.asAttrs';

in
forEachSystem (system: importAsAttrs' {
  path = ./.;
  apply = _: check:
    recursiveUpdate
      (check (inputs // {
        inherit system;
        inherit (pkgs.${system}.${system}) pkgs;
      }))
      { inherit (lib.nixplusplus) meta; }
  ;
  inherit system;
})
