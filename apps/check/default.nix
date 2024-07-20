# This file is part of Nix++.
# Copyright (C) 2023-2024 Leandro Emmanuel Reina Kiperman.
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
let
  inherit (pkgs.lib) escapeShellArg;

in
writeShellApplication {
  name = builtins.baseNameOf ./.;
  runtimeInputs = [
    findutils
    jq
    nix
    nixpkgs-fmt
    statix
  ];
  text = ''
    XC=0

    printf '# Get paths ####################################################\n'
    # shellcheck disable=SC2016
    mapfile -t drvs < <(
      (
        nix --no-warn-dirty eval .#packages --json --apply ${escapeShellArg ''
          packages:
            let
              systems = builtins.attrNames packages;

            in
            builtins.map (localSystem:
              builtins.map (crossSystem:
                let
                  pkg = packages.''${localSystem}.''${crossSystem};

                in
                [ pkg._all.drvPath pkg._apps.drvPath ]
              ) systems
            ) systems
        ''} \
        | jq -r .[][][] ;
      ) | sort -u ;
    ) || XC="$(( XC + 0x01 ))"

    printf '\n# Check format #################################################\n'
    (
      nixpkgs-fmt --check -- . ;
    ) || XC="$(( XC + 0x02 ))"

    printf '\n# Check linting ################################################\n'
    (
      statix check --config ${import ./lint-config.nix args} -- . ;
    ) || XC="$(( XC + 0x04 ))"

    [ $(( XC & 0x01 )) -ne 0 ] \
    || printf '\n# Check build ##################################################\n'
    [ $(( XC & 0x01 )) -ne 0 ] \
    || (
      printf '%s\n' "''${drvs[@]}" \
      | xargs -r nix --no-warn-dirty --print-build-logs \
        build --no-link ;
    ) || XC="$(( XC + 0x08 ))"

    [ $(( XC & 0x08 )) -ne 0 ] \
    || printf '\n# Check flake ##################################################\n'
    [ $(( XC & 0x08 )) -ne 0 ] \
    || (
      nix --no-warn-dirty --print-build-logs --keep-going flake check -- . ;
    ) || XC="$(( XC + 0x10 ))"

    printf '\n# Finished #####################################################\n'
    printf '\x1B[1;%dmXC: 0x%02X\x1B[0m\n' \
      "$([ "$XC" -eq 0 ] && printf 32 || printf 31)" \
      "$XC"
    exit $XC
  '';
}
