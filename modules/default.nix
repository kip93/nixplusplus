{ self, ... } @ inputs:
self.lib.nixplusplus.import.asAttrs' {
  path = ./.;
  func = module: module inputs;
}
