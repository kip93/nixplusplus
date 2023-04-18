{ nixpkgs, self, ... } @ inputs:
{
  # A shorthand expression to get cross-compiled packages. First key is the
  # build machine; the second, the target one.
  # It also applies the overlays from this flake.
  pkgs = self.lib.forEachSupportedSystem' (localSystem: crossSystem: import nixpkgs {
    localSystem.config =
      nixpkgs.lib.systems.parse.tripleFromSystem
        (nixpkgs.lib.systems.parse.mkSystemFromString localSystem)
    ;
    crossSystem.config =
      nixpkgs.lib.systems.parse.tripleFromSystem
        (nixpkgs.lib.systems.parse.mkSystemFromString crossSystem)
    ;
    overlays = with self.overlays; [ default ];
  });
}
