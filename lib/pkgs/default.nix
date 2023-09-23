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

{ nixpkgs, self, ... } @ _inputs: {
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
    overlays = [ self.overlays.default ];
  });
}
