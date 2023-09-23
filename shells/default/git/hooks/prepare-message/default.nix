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

{ pkgs, ... }:
with pkgs; {
  pre-commit.hooks.prepare-commit-template = {
    enable = true;
    description = "Add some dynamic info onto the commit message template";
    stages = [ "prepare-commit-msg" ];
    entry = "${writeShellScript "prepare-commit-template.sh" ''
      # Set search path
      export PATH=${lib.escapeShellArg (lib.makeBinPath [
        coreutils
        git
        gnused
      ])}

      exec 1>&2 # stdout -> stderr

      # Remove default help message.
      sed -i '/^# Please enter the commit message for your changes./Q' "$1"

      # Put in custom help message.
      printf '# About to commit the following changes:\n' >>"$1"
      git status --short \
      | sed -nE 's/^(\w)(.)/#   \1/p' >>"$1"
    ''}";
  };
}
