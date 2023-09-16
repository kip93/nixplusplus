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

{ npppkgs, pkgs, self, ... } @ args:
{
  inherit pkgs;
  inputs = builtins.removeAttrs args [ "pkgs" "system" ];
  modules = [
    # Basics
    ({ pkgs, ... }: {
      packages = with pkgs; [ cacert coreutils nixVersions.unstable ];
      enterShell = ''
        export PS1="\[\e[0m\][\[\e[36m\] nix++ \[\e[0m\]] \[\e[1m\]\$\[\e[0m\] "
        EDITOR="''${EDITOR:-${npppkgs.vim-minimal}/bin/vim}" # Default to vim
        export EDITOR
      '';
    })
  ] ++ (self.lib.import.asList ./.);
}
