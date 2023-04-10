{ self, flake-utils, ... } @ inputs:
let
  inherit (self) lib;
  inherit (lib.nixplusplus) forEachSystem pkgs;
  importAsAttrs' = lib.nixplusplus.import.asAttrs';
  inherit (flake-utils.lib) mkApp;

in
forEachSystem (system: importAsAttrs' {
  path = ./.;
  apply = _: app:
    mkApp {
      drv = (app (inputs // {
        inherit system;
        inherit (pkgs.${system}.${system}) pkgs;
      })).overrideAttrs (super: {
        meta = super.meta // lib.nixplusplus.meta;
      });
    }
  ;
  inherit system;
})
