{ self, ... } @ inputs:
self.lib.nixplusplus.import.asAttrs' {
  path = ./.;
  func = overlay: overlay inputs;
}
