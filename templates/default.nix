{ self, ... } @ inputs:
self.lib.nixplusplus.import.asAttrs' {
  path = ./.;
  apply = _: template: template inputs;
}
