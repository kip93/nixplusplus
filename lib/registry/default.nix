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

{ nixpkgs, self, ... } @ inputs: {
  # A collection of flakes, taken from the inputs of this flake. Useful for
  # overriding NixOS default ones.
  flakes.registry = nixpkgs.lib.filterAttrs
    (name: value:
      # Workaround for nix-systems#6 (hopefully will be fixed with nix#3978)
      name != "systems" &&
      value._type or null == "flake"
    )
    ((builtins.removeAttrs inputs [ "self" ]) // {
      # Rename self into something actually useful.
      nixplusplus = self;
      # And alias it because nixplusplus is too long.
      npp = self;
    })
  ;
}
