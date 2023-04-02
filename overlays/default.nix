{ self, ... } @ inputs:
self.lib.nixplusplus.import.asAttrs' {
  path = ./.;
  func = x: x inputs;
}
