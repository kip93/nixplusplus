{ self, ... } @ inputs:
self.lib.nixplusplus.import.asAttrs' {
  path = ./.;
  func = template: template inputs;
}
