{ self, ... } @ inputs:
self.lib.import.asModules' {
  path = ./.;
  apply = name: module: { config, ... }: {
    imports = [ (module inputs) ];
    meta = {
      inherit (self.lib.meta) maintainers;
      doc = config.nixplusplus.${name}.meta.doc or null;
    };
  };
}
