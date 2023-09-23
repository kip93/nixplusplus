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

# TODO echo $@
{ pkgs, ... }:
with pkgs; {
  pre-commit.hooks.check-whitespace = {
    enable = true;
    description = "Check for whitepace errors";
    stages = [ "commit" "merge-commit" ];
    entry = "${writeShellScript "check-whitespace.sh" ''
      # Set search path
      export PATH=${lib.escapeShellArg (lib.makeBinPath [
        coreutils
        findutils
        git
      ])}

      exec 1>&2 # stdout -> stderr

      # Show whitespace errors.
      if ! git diff-index --check --cached HEAD -- >/dev/null ; then
        printf '\x1B[31mERROR:\x1B[0m Found files with whitespace errors.\n'
        git diff-index --cached --name-only -z HEAD -- \
        | while IFS= read -r -d $'\0' f ; do \
          git diff-index --check --cached HEAD -- "$f" >/dev/null \
          || printf '%s\0' "$f" \
        ; done \
        | xargs -0 printf ' * %s\n'
        exit 1
      fi
    ''}";
    pass_filenames = false;
  };
}
