{ self, ... } @ inputs:
self.lib.import.asTemplates' {
  path = ./.;
  apply = _: template: template inputs;
}
