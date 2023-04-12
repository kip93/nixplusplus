{ self, ... } @ inputs:
self.lib.import.asApps' {
  path = ./.;
  apply = _: system: app:
    (app (inputs // {
      inherit system;
      inherit (self.lib.pkgs.${system}.${system}) pkgs;
    })).overrideAttrs (super: {
      meta = (super.meta or { }) // self.lib.meta;
    })
  ;
}
