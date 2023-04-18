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
