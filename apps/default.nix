{ self, flake-utils, ... } @ inputs:
let
  inherit (self) lib;
  inherit (lib.nixplusplus) forEachSystem pkgs;
  importAsAttrs' = lib.nixplusplus.import.asAttrs';
  inherit (flake-utils.lib) mkApp;

in
forEachSystem (system: {
  name = system;
  value = importAsAttrs' {
    path = ./.;
    func = app:
      mkApp {
        drv = app (inputs // {
          inherit system;
          inherit (pkgs.${system}.${system}) pkgs;
        });
      }
    ;
    inherit system;
  };
})
