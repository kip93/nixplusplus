{ self, ... } @ inputs:
let
  inherit (self) lib;
  inherit (lib.nixplusplus) forEachSystem pkgs;
  importAsAttrs' = lib.nixplusplus.import.asAttrs';

in
forEachSystem (system: {
  name = system;
  value = importAsAttrs' {
    path = ./.;
    func = check:
      check (inputs // {
        inherit system;
        inherit (pkgs.${system}.${system}) pkgs;
      })
    ;
    inherit system;
  };
})
