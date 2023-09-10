# This file is part of Nix++.
# Copyright (C) 2023 Leandro Emmanuel Reina Kiperman.
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

{ nixpkgs, ... } @ inputs:
rec {
  # This flake's supported systems. Should cover the good majority of cases.
  # SEE ALSO: ${nixpkgs}/lib/systems/doubles.nix
  supportedSystems = _systems ++ _extraSystems;
  supportedSystems' = builtins.groupBy
    (system: builtins.head (builtins.match ".*-(.*)" system))
    supportedSystems
  ;
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
    "i686-linux"
    "armv6l-linux"
    # MacOS
    "x86_64-darwin"
    "aarch64-darwin"
  ];

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
  # Makes sure only allow mappings for the differents archs while avoiding
  # mixing different operating systems, since those can cause a fuck-ton of
  # issues. Additionally, given https://github.com/NixOS/nixpkgs/issues/180771,
  # I also had to disable `aarch64-darwin -> x86_64-darwin`.
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
              (builtins.filter
                (crossSystem:
                  builtins.head (builtins.match ".*-(.*)" localSystem)
                  ==
                  builtins.head (builtins.match ".*-(.*)" crossSystem)
                  && # TODO NixOS/nixpkgs#180771
                  (localSystem != "aarch64-darwin" || crossSystem != "x86_64-darwin")
                )
                systems
              )
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
