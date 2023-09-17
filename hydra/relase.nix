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

{ nixpkgs, declInput, ... }:
with import nixpkgs { };
{
  jobsets = runCommand "spec.json" { } ''
    cat <<EOF
    ${builtins.toXML declInput}
    EOF
    printf %s ${lib.escapeShellArg (builtins.toJSON {
      main = {
        type = 1; # Flake support
        enabled = true;
        hidden = false;
        flake = "git+ssh://git.kip93.net/nix++";
        checkinterval = 900; # 15m
        keepnr = 10;
      };
    })} >$out
  '';
}
