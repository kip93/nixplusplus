# This file is part of Nix++.
# Copyright (C) 2023-2024 Leandro Emmanuel Reina Kiperman.
#
# Nix++ is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# Nix++ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# SEE ALSO: ${nixpkgs}/lib/systems/doubles.nix
{ nixpkgs, ... } @ _inputs: rec {
  # Systems I personally own and use, so they should be somewhat well tested.
  _systems = [
    # Linux
    "x86_64-linux"
    "aarch64-linux"
    "armv7l-linux"
  ];
  # Everything here I'm willing to try and support; but I don't personally use
  # any of these, so they may be under-tested.
  _extraSystems = [
    # Linux
    "riscv64-linux"
    # MacOS
    "x86_64-darwin"
    "aarch64-darwin"
    # BSD
    ## NetBSD
    "x86_64-netbsd"
    "aarch64-netbsd"
    "armv7l-netbsd"
    "riscv64-netbsd"
    ## FreeBSD
    "x86_64-freebsd"
    ## OpenBSD
    "x86_64-openbsd"
  ];

  # You usually don't compile from an ARM system to an X86 one, so have some
  # form of somewhat logical cross compilation setup.
  # Also takes care of nixpkgs#180771
  _crossArhitectures = rec {
    x86_64 = [ "x86_64" ] ++ aarch64;
    aarch64 = [ "aarch64" ] ++ armv7l;
    armv7l = [ "armv7l" ] ++ riscv64;
    riscv64 = [ "riscv64" ];
  };

  # This flake's supported systems. Should cover the good majority of cases.
  supportedSystems = builtins.sort builtins.lessThan (_systems ++ _extraSystems);
  supportedSystems' = builtins.groupBy
    (system: builtins.head (builtins.match ".*-(.*)" system))
    supportedSystems
  ;

  # This flake's supported systems, paired up in such a way to make sure to only
  # allow mappings for the differents archs while avoiding mixing different
  # operating systems, since those cases can cause a fuck-ton of issues.
  supportedCrossSystems = builtins.foldl' (x: y: x // y) { }
    (builtins.attrValues supportedCrossSystems')
  ;
  supportedCrossSystems' = builtins.mapAttrs
    (_: systems: builtins.listToAttrs
      (builtins.map
        (localSystem: {
          name = localSystem;
          value = builtins.filter
            (crossSystem:
              builtins.elem (builtins.head (builtins.match "(.*)-.*" crossSystem))
                _crossArhitectures.${builtins.head (builtins.match "(.*)-.*" localSystem)}
            )
            systems
          ;
        })
        systems
      )
    )
    supportedSystems'
  ;

  # Maps a function over each given system.
  # For a given `x`, it returns `{ <system> = x; }`.
  forEachSystem = systems: mapFunction:
    builtins.listToAttrs
      (builtins.map
        (name: { inherit name; value = mapFunction name; })
        systems
      )
  ;

  # Maps a function over each of the elements of the given system matrix.
  # Ensures that no "weird" mix up of systems occur (see
  # `supportedCrossSystems`).
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
              (nixpkgs.lib.intersectLists systems supportedCrossSystems.${localSystem})
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
