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

{ pkgs, ... } @ args:
with pkgs;
writeShellApplication {
  name = builtins.baseNameOf ./.;
  runtimeInputs = [
    findutils
    gawk
    git
    gnugrep
    (python3.withPackages (pypkgs: with pypkgs; [ more-itertools ]))
  ];
  text = ''
    current_year="$(date +%Y)" ${/* Get the current year first, in case it's the night of 31st of December. */ ""}
    git status -z ${/* Find changed files with headers. */ ""} \
    | cut -zc4- \
    | while IFS= read -r -d $'\0' f ; do \
      awk -v f="$f" '/\yThis file is part of Nix\+\+\./{printf "%s\0",f}/^\s*$/{next}{exit}' \
    ; done \
    | while IFS= read -r -d $'\0' f ; do ${/* Patch their headers' copyright years. */ ""} \
      ( ${/* Parse the copyright years. */ ""} \
        ( ${/* Parse the year ranges. */ ""} \
          awk '/\yCopyright \(C\)/{printf "%s\0",$0;exit}' "$f" \
          | grep -zoP '\d+(-\d+)?' \
          | (grep -z -||:) \
          | while IFS= read -r -d $'\0' y ; do \
            printf "%s\0" $(seq "''${y%-*}" "''${y#*-}") \
          ; done \
        ) ; ( ${/* Get the plain years as-is. */ ""} \
          awk '/\yCopyright \(C\)/{printf "%s\0",$0;exit}' "$f" \
          | grep -zoP '\d+(-\d+)?' \
          | (grep -vz -||:) \
        ) ; printf '%s\0' "''${current_year}" \
      ) | sort -nuz \
      | python3 -c ${lib.escapeShellArg /* Collect the years into a pretty string. */ ''
        from more_itertools import consecutive_groups
        print(", ".join(
          map(
            lambda x: str(x[0]) if len(x) == 1 else f"{x[0]}-{x[-1]}",
            map(list, consecutive_groups(map(int, input().split("\0")[:-1])))),
          ),
          end = "\0",
        )
      ''} ${/* Now place the new years in place of the old ones. */ ""} \
      | xargs -0I{} awk -i inplace '{print gensub(/^(.+\yCopyright \(C\)) +[-, 0-9]+/,"\\1 {} ","g")}' "$f" \
    ; done
  '';
}
