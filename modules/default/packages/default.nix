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

{ self, ... } @ inputs:
{ pkgs, ... }:
{
  config = {
    environment = {
      defaultPackages =
        with pkgs;
        with self.packages.${pkgs.buildPlatform.system}.${pkgs.hostPlatform.system};
        self.lib.mkForce [
          bash
          cacert
          coreutils-full
          curl
          gawk
          git
          gnugrep
          gnupg
          gnused
          gnutar
          htop
          less
          openssh
          p7zip
          pigz
          pixz
          vim-minimal
        ]
      ;
      systemPackages = [ ];
      variables = {
        EDITOR = "vim";
        PAGER = "less"; # TODO vimpager
      };
    };

    security.sudo = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
}
