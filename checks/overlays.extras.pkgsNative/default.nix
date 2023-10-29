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

{ pkgs, self, ... } @ _args:
let
  x86_64Pkgs = self.lib.pkgs.x86_64-linux.x86_64-linux;
  aarch64Pkgs = self.lib.pkgs.aarch64-linux.aarch64-linux;
  crossPkgs = self.lib.pkgs.x86_64-linux.aarch64-linux;

in
pkgs.testers.nixTest {
  name = builtins.baseNameOf ./.;
  checks = {
    sameSystem = {
      expr =
        x86_64Pkgs.pkgsNative.buildPlatform == x86_64Pkgs.buildPlatform
        &&
        x86_64Pkgs.pkgsNative.hostPlatform == x86_64Pkgs.hostPlatform
        &&
        x86_64Pkgs.pkgsNative.bash == x86_64Pkgs.bash
      ;
      expected = true;
    };
    crossCompilation = {
      expr =
        crossPkgs.pkgsNative.buildPlatform == crossPkgs.hostPlatform
        &&
        crossPkgs.pkgsNative.hostPlatform == crossPkgs.hostPlatform
        &&
        crossPkgs.pkgsNative.bash == aarch64Pkgs.bash
      ;
      expected = true;
    };
    sameSystemTwice = {
      expr =
        x86_64Pkgs.pkgsNative.pkgsNative.buildPlatform == x86_64Pkgs.buildPlatform
        &&
        x86_64Pkgs.pkgsNative.pkgsNative.hostPlatform == x86_64Pkgs.hostPlatform
        &&
        x86_64Pkgs.pkgsNative.pkgsNative.bash == x86_64Pkgs.bash
      ;
      expected = true;
    };
    crossCompilationTwice = {
      expr =
        crossPkgs.pkgsNative.pkgsNative.buildPlatform == crossPkgs.hostPlatform
        &&
        crossPkgs.pkgsNative.pkgsNative.hostPlatform == crossPkgs.hostPlatform
        &&
        crossPkgs.pkgsNative.pkgsNative.bash == aarch64Pkgs.bash
      ;
      expected = true;
    };
  };
}
