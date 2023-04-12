{ pkgs, self, ... } @ args:
with pkgs;
let
  inherit (pkgs.lib) escapeShellArg;
  inherit (self.lib) supportedSystems;

in
writeShellApplication {
  name = builtins.baseNameOf ./.;
  runtimeInputs = [
    findutils
    jq
    nix
    nixpkgs-fmt
    statix
    vulnix
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
      statix check --config ${import ../lint/config.nix args} -- . ;
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

    [ $(( XC & 0x09 )) -ne 0 ] \
    || printf '\n# Check vulnerabilities ########################################\n'
    [ $(( XC & 0x09 )) -ne 0 ] \
    || (
      printf '%s\n' "''${drvs[@]}" \
      | xargs -r vulnix ;
    ) || XC="$(( XC + 0x20 ))"

    printf '\n# Finished #####################################################\n'
    printf '\x1B[1;%dmXC: 0x%02X\x1B[0m\n' \
      "$([ "$XC" -eq 0 ] && printf 32 || printf 31)" \
      "$XC"
    exit $XC
  '';
}
