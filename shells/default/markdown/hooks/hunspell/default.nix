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

{ config, lib, pkgs, ... }:
let
  # Use british english
  lang = "en_GB";
  dict = pkgs.hunspellDicts.en_GB-large;
  # Add custom words
  words = [
    "agenix"
    "backends"
    "dev"
    "devenv"
    "direnv"
    "FlakeHub"
    "fmt"
    "gc"
    "GiB"
    "github"
    "GitLab"
    "gitlab"
    "GPLv3"
    "ish"
    "jobset"
    "json"
    "kip93"
    "nginx"
    "NixOS"
    "nixplusplus"
    "nixpkgs"
    "pkgs"
    "repo"
    "schema"
    "Schema"
    "schemas"
    "Schemas"
    "statix"
    "TODO"
    "upstreamed"
  ];

in
{
  pre-commit.hooks.hunspell = {
    enable = true;
    # Don't check license file
    files = lib.mkForce "(^|/)README\\.md$";
    # Use specific dictionary and add custom words
    entry = lib.mkForce "${with pkgs; writeShellScript "hunspell-wrapper.sh" ''
      set +e -u -o pipefail
      export PATH=${lib.escapeShellArg (lib.makeBinPath [
        bash
        config.pre-commit.tools.hunspell
        pandoc # TODO Some other alternative that is not 5GiB+?
      ])}

      export DICPATH=${
        lib.escapeShellArg (lib.makeSearchPath "share/hunspell" [ dict ])
      }
      words=${runCommand "custom-dict.txt" { } ''
        export PATH=${lib.escapeShellArg (lib.makeBinPath [
          coreutils
        ])}
        printf '%s\n' ${lib.escapeShellArgs words} | sort -u >$out
      ''}

      XC=0
      for file in "$@" ; do
        stdout="$( \
          pandoc -t plain -- "$file" \
          | hunspell -d ${lang} -p $words -l \
        )"
        xc=$?
        if [ $xc -ne 0 ] ; then
          printf '%s\n' "./$file"
          printf '%s' "$stdout"
          printf '\n\n'
        fi
        (( XC |= $xc ))
      done
      exit $XC
    ''}";
  };
}
