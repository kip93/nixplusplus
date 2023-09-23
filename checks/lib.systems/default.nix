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

{ nixpkgs, pkgs, self, ... } @ _args:
pkgs.nixTest {
  name = builtins.baseNameOf ./.;
  checks = {
    systems_exist = {
      expr = builtins.all
        (x: builtins.any (y: x == y) nixpkgs.lib.systems.doubles.all)
        self.lib.supportedSystems
      ;
      expected = true;
    };
    for_each_empty = {
      expr = self.lib.forEachSystem [ ] (_: { });
      expected = { };
    };
    for_each = {
      expr = self.lib.forEachSystem [ "x86_64-linux" ] (x: [
        (builtins.elemAt (builtins.split "-" x) 0)
        (builtins.elemAt (builtins.split "-" x) 2)
      ]);
      expected = {
        x86_64-linux = [ "x86_64" "linux" ];
      };
    };
    for_each_2 = {
      expr = self.lib.forEachSystem [ "x86_64-linux" "aarch64-linux" ] (x: [
        (builtins.elemAt (builtins.split "-" x) 0)
        (builtins.elemAt (builtins.split "-" x) 2)
      ]);
      expected = {
        x86_64-linux = [ "x86_64" "linux" ];
        aarch64-linux = [ "aarch64" "linux" ];
      };
    };
    for_matrix_empty = {
      expr = self.lib.forEachSystem' [ ] (_: _: { });
      expected = { };
    };
    for_matrix = {
      expr = self.lib.forEachSystem' [ "x86_64-linux" ] (x: y: [
        [
          (builtins.elemAt (builtins.split "-" x) 0)
          (builtins.elemAt (builtins.split "-" x) 2)
        ]
        [
          (builtins.elemAt (builtins.split "-" y) 0)
          (builtins.elemAt (builtins.split "-" y) 2)
        ]
      ]);
      expected = {
        x86_64-linux = {
          x86_64-linux = [ [ "x86_64" "linux" ] [ "x86_64" "linux" ] ];
        };
      };
    };
    for_matrix_2 = {
      expr = self.lib.forEachSystem' [ "x86_64-linux" "aarch64-linux" ] (x: y: [
        [
          (builtins.elemAt (builtins.split "-" x) 0)
          (builtins.elemAt (builtins.split "-" x) 2)
        ]
        [
          (builtins.elemAt (builtins.split "-" y) 0)
          (builtins.elemAt (builtins.split "-" y) 2)
        ]
      ]);
      expected = {
        aarch64-linux = {
          aarch64-linux = [ [ "aarch64" "linux" ] [ "aarch64" "linux" ] ];
          x86_64-linux = [ [ "aarch64" "linux" ] [ "x86_64" "linux" ] ];
        };
        x86_64-linux = {
          aarch64-linux = [ [ "x86_64" "linux" ] [ "aarch64" "linux" ] ];
          x86_64-linux = [ [ "x86_64" "linux" ] [ "x86_64" "linux" ] ];
        };
      };
    };
    is_supported_implicit = {
      expr = self.lib.isSupported { } "x86_64-linux";
      expected = true;
    };
    is_supported_explicit = {
      expr = self.lib.isSupported { meta.platforms = [ "x86_64-linux" ]; } "x86_64-linux";
      expected = true;
    };
    is_not_supported = {
      expr = self.lib.isSupported { meta.platforms = [ "x86_64-linux" ]; } "aarch64-linux";
      expected = false;
    };
  };
}
