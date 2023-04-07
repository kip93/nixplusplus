{ ... } @ inputs:
rec {
  supportedSystems = [ "x86_64-linux" "aarch64-linux" "armv7l-linux" ];
  forEachSystem = mapFunction:
    builtins.listToAttrs
      (builtins.map
        mapFunction
        supportedSystems
      )
  ;
}
