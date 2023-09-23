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
  pre-commit.hooks.check-commit-message = {
    enable = true;
    description = "Check commit message";
    stages = [ "commit-msg" ];
    entry = "${writeShellScript "check-commit-message.sh" ''
      # Set search path
      export PATH=${lib.escapeShellArg (lib.makeBinPath [
        coreutils
        gawk
        gnused
      ])}

      exec 1>&2 # stdout -> stderr

      # Delete irrelevant lines.
      sed -iE -n '/^\s*#/d;p' "$1"
      # shellcheck disable=SC2016
      sed -iE -n '/^\s*$/!{p;b};h;:loop;$b end;n;/^\s*$/b loop;:end;/^\s*$/{p;b};H;x;p' "$1"

      # Check the commit message.
      if [ "$(awk '{printf "%s",$0;exit}' "$1" | wc -c)" -eq 0 ] ; then
        printf '\x1B[31mERROR:\x1B[0m Missing commit message.\n'
        exit 1

      elif [ "$(awk '{printf "%s",$0;exit}' "$1" | wc -c)" -gt 50 ] ; then
        printf '\x1B[31mERROR:\x1B[0m Commit message is over 50 characters.\n'
        exit 1

      elif [ "$(awk 'NR==1{next}length($0)>72{printf "%s",$0}' "$1" | wc -c)" -gt 0 ] ; then
        printf '\x1B[31mERROR:\x1B[0m Found commit description line(s) over 72 characters.\n'
        exit 1
      fi
    ''}";
  };
}
