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

{ nixpkgs, pkgs, self, ... } @ _args:
pkgs.testers.nixTest {
  name = builtins.baseNameOf ./.;
  checks = {
    systemsExist = {
      expr = builtins.all
        (x: builtins.any (y: x == y) nixpkgs.lib.systems.doubles.all)
        self.lib.supportedSystems
      ;
      expected = true;
    };
    forEachEmpty = {
      expr = self.lib.forEachSystem [ ] (_: { });
      expected = { };
    };
    forEach = {
      expr = self.lib.forEachSystem [ "x86_64-linux" ] (x: [
        (builtins.elemAt (builtins.split "-" x) 0)
        (builtins.elemAt (builtins.split "-" x) 2)
      ]);
      expected = {
        x86_64-linux = [ "x86_64" "linux" ];
      };
    };
    forEach2 = {
      expr = self.lib.forEachSystem [ "x86_64-linux" "aarch64-linux" ] (x: [
        (builtins.elemAt (builtins.split "-" x) 0)
        (builtins.elemAt (builtins.split "-" x) 2)
      ]);
      expected = {
        x86_64-linux = [ "x86_64" "linux" ];
        aarch64-linux = [ "aarch64" "linux" ];
      };
    };
    forMatrixEmpty = {
      expr = self.lib.forEachSystem' [ ] (_: _: { });
      expected = { };
    };
    forMatrix = {
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
    forMatrix2 = {
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
        };
        x86_64-linux = {
          aarch64-linux = [ [ "x86_64" "linux" ] [ "aarch64" "linux" ] ];
          x86_64-linux = [ [ "x86_64" "linux" ] [ "x86_64" "linux" ] ];
        };
      };
    };
    isSupportedImplicit = {
      expr = self.lib.isSupported { } "x86_64-linux";
      expected = true;
    };
    isSupportedExplicit = {
      expr = self.lib.isSupported { meta.platforms = [ "x86_64-linux" ]; } "x86_64-linux";
      expected = true;
    };
    isNotSupported = {
      expr = self.lib.isSupported { meta.platforms = [ "x86_64-linux" ]; } "aarch64-linux";
      expected = false;
    };
  };
}
