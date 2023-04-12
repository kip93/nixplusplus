{ self, ... } @ inputs:
self.lib.import.asPackages' {
  path = ./.;
  apply = _: localSystem: crossSystem: package:
    (package (inputs // {
      inherit (self.lib.pkgs.${localSystem}.${crossSystem}) pkgs;
      inherit localSystem crossSystem;
    })).overrideAttrs (super: {
      meta = super.meta // {
        inherit (self.lib.meta) homepage maintainers;
        license = super.meta.license or self.lib.meta.license;
      };
    })
  ;
}
