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

{ nixpkgs, self, ... } @ inputs:
self.lib.import.asChecks' {
  path = ./.;
  apply = _: system: check:
    nixpkgs.lib.recursiveUpdate
      (check (inputs // {
        inherit system;
        inherit (self.lib.pkgs.${system}.${system}) pkgs;
      }))
      {
        meta = {
          inherit (self.lib.meta) homepage license maintainers;
          # NixOS test are Linux exclusive.
          platforms = builtins.filter
            (nixpkgs.lib.hasSuffix "-linux")
            self.lib.supportedSystems
          ;
        };
      }
  ;
}
