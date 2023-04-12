{ nixpkgs, ... } @ inputs:
rec {
  # This flake's supported systems.
  # SEE ALSO: ${nixpkgs}/lib/systems/doubles.nix
  supportedSystems = [ "x86_64-linux" "aarch64-linux" "armv7l-linux" ];

  # Maps a function over each given system.
  # For a given `x`, it returns `{ <system> = x; }`.
  forEachSystem = systems: mapFunction:
    builtins.listToAttrs
      (builtins.map
        (name: { inherit name; value = mapFunction name; })
        systems
      )
  ;

  # Maps a function over each of the elements of the supported system matrix.
  # For a given `x`, it returns `{ <local>.<target> = x; }`.
  forEachSystem' = systems: mapFunction:
    builtins.listToAttrs
      (builtins.map
        (localSystem: {
          name = localSystem;
          value = builtins.listToAttrs
            (builtins.map
              (crossSystem: {
                name = crossSystem;
                value = mapFunction localSystem crossSystem;
              })
              systems
            )
          ;
        })
        systems
      )
  ;

  # Same as above, but with supported systems.
  forEachSupportedSystem = forEachSystem supportedSystems;
  forEachSupportedSystem' = forEachSystem' supportedSystems;

  # Checks if a derivation supports the given system.
  isSupported = drv: system:
    (!nixpkgs.lib.hasAttrByPath [ "meta" "platforms" ] drv)
    || (builtins.any (p: p == system) drv.meta.platforms)
  ;
}
