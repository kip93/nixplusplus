{ self, ... } @ inputs:
self.lib.import.asOverlays' {
  path = ./.;
  apply = _: overlay: overlay inputs;
}
