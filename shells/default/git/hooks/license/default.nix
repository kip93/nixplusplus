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
  pre-commit.hooks.check-licenses = {
    enable = true;
    description = "Check for outdated licenses";
    stages = [ "commit" "merge-commit" ];
    entry = "${writeShellScript "check-licenses.sh" ''
      # Set search path
      export PATH=${lib.escapeShellArg (lib.makeBinPath [
        coreutils
        findutils
        gawk
        git
        gnugrep
      ])}

      exec 1>&2 # stdout -> stderr

      # Show outdated license headers.
      current_year="$(date +%Y)" ${/* Get the current year first, in case it's the night of 31st of December. */ ""}
      files_with_outdated_license() (
        git diff --cached --name-only -z HEAD -- ${/* Find staged files with headers. */ ""} \
        | while IFS= read -r -d $'\0' f ; do \
          git show ":$f" \
          | awk -v f="$f" '/\yThis file is part of Nix\+\+\./{printf "%s\0",f}/^\s*$/{next}{exit}' \
        ; done \
        | while IFS= read -r -d $'\0' f ; do ${/* Check their headers' copyright years. */ ""} \
          ( ${/* Parse the copyright years. */ ""} \
            ( ${/* Parse the year ranges. */ "" } \
              git show ":$f" \
              | awk '/\yCopyright \(C\)/{printf "%s\0",$0;exit}' \
              | grep -zoP '\d+(-\d+)?' \
              | (grep -z -||:) \
              | while IFS= read -r -d $'\0' y ; do \
                printf "%s\0" $(seq "''${y%-*}" "''${y#*-}") \
              ; done \
            ) ; ( ${/* Get the plain years as-is. */ ""} \
              git show ":$f" \
              | awk '/\yCopyright \(C\)/{printf "%s\0",$0;exit}' \
              | grep -zoP '\d+(-\d+)?' \
              | (grep -vz -||:) \
            ) \
          ) | sort -nuz \
          | grep -qP "^''${current_year}$" ${/* Check if any of the listed years correspond to the current one. */ ""} \
          || printf '%s\0' "$f" ${/* Print the paths of the files that failed the check. */ ""} \
        ; done
      )
      if [ "$(files_with_outdated_license | wc -c)" -ne 0 ] ; then
        printf '\x1B[31mERROR:\x1B[0m Found files with outdated licenses.\n'
        files_with_outdated_license \
        | xargs -0 printf ' * %s\n'
        exit 1
      fi
    ''}";
    pass_filenames = false;
  };
}
