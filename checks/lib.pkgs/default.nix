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
pkgs.nixTest {
  name = builtins.baseNameOf ./.;
  checks = {
    localBuild = {
      expr =
        let
          pkgs' = self.lib.pkgs.x86_64-linux.x86_64-linux;
        in
        pkgs'.buildPlatform == pkgs'.targetPlatform
      ;
      expected = true;
    };
    crossCompilation = {
      expr =
        let
          pkgs' = self.lib.pkgs.x86_64-linux.aarch64-linux;
        in
        pkgs'.buildPlatform.system == "x86_64-linux"
        &&
        pkgs'.targetPlatform.system == "aarch64-linux"
      ;
      expected = true;
    };
  };
}
