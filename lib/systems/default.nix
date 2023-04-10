{ ... } @ inputs:
rec {
  # This flake's supported systems.
  supportedSystems = [ "x86_64-linux" "aarch64-linux" "armv7l-linux" ];
  # Maps a function over each supported system.
  forEachSystem = mapFunction:
    builtins.listToAttrs
      (builtins.map
        (name: { inherit name; value = mapFunction name; })
        supportedSystems
      )
  ;
  # Maps a function over each of the elements of the supported system matrix.
  forEachSystem' = mapFunction:
    forEachSystem (s1: forEachSystem (s2: mapFunction s1 s2))
  ;
}
