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

{ npppkgs, pkgs, self, ... } @ args: {
  inherit pkgs;
  inputs = builtins.removeAttrs args [ "pkgs" "system" ];
  modules = [
    # Basics
    ({ lib, pkgs, ... }: {
      name = "Nix++";
      packages = with pkgs; [ cacert coreutils nixVersions.unstable ];
      enterShell = lib.mkBefore ''
        EDITOR="''${EDITOR:-${npppkgs.vim-minimal}/bin/vim}" # Default to vim
        export EDITOR

        printf ${lib.escapeShellArg ''
          \x1B[0m
            \x1B[96m...      \x1B[34m+++
            \x1B[96m::: \x1B[34m+++  +++    \x1B[0;1mNix++ dev shell\x1B[0m
            \x1B[96m:::: \x1B[34m+++ +++
            \x1B[96m:::::: \x1B[34m+++++    \x1B[0mI'm making my own shell with linters and git hooks!
            \x1B[96m::: ::: \x1B[34m++++    \x1B[0;2mAnd bugs. So many bugs. Plz send help.\x1B[0m
            \x1B[96m:::  ::: \x1B[34m+++
            \x1B[96m:::      \x1B[34m''''
          \x1B[0m
            Loading environment ...

        ''}
      '';
    })
  ] ++ (self.lib.import.asList ./.);
}
