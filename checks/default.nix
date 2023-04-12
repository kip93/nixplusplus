{ nixpkgs, self, ... } @ inputs:
self.lib.import.asChecks' {
  path = ./.;
  apply = _: system: check:
    nixpkgs.lib.recursiveUpdate
      (check (inputs // {
        inherit system;
        inherit (self.lib.pkgs.${system}.${system}) pkgs;
      }))
      { inherit (self.lib) meta; }
  ;
}
