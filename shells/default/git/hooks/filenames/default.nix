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
  pre-commit.hooks.check-filenames = {
    enable = true;
    description = "Check filenames are ASCII only";
    stages = [ "commit" "merge-commit" ];
    entry = "${writeShellScript "check-filenames.sh" ''
      # Set search path
      export PATH=${lib.escapeShellArg (lib.makeBinPath [
        coreutils
        findutils
        git
        gnugrep
      ])}

      exec 1>&2 # stdout -> stderr

      # Check for non-ascii file names.
      bad_names() (
        git diff --cached --name-only -z HEAD -- \
        | LC_ALL=C grep -zP '[^\x20-\x7E]'
      )
      if [ "$(bad_names | wc -c)" -ne 0 ] ; then
        printf '\x1B[31mERROR:\x1B[0m Filenames with invalid characters found.\n'
        bad_names \
        | xargs -0 printf ' * %s\n'
        exit 1
      fi
    ''}";
    pass_filenames = false;
  };
}
