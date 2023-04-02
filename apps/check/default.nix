{ flake-utils, nixpkgs, self, system, nixpkgs-fmt, statix, ... } @ inputs:
with nixpkgs.legacyPackages.${system};
flake-utils.lib.mkApp {
  drv = writeShellApplication {
    name = builtins.baseNameOf ./.;
    runtimeInputs = [
      findutils
      nix
      nixpkgs-fmt.defaultPackage.${system}
      statix.defaultPackage.${system}
      vulnix
    ];
    text = ''
      XC=0

      printf '# Check flake ##################################################\n'
      (
        nix --option warn-dirty false -L flake check -- ${lib.escapeShellArg self} ;
      ) || XC="$(( XC + 0x01 ))"

      printf '\n# Check format #################################################\n'
      (
        nixpkgs-fmt --check -- ${lib.escapeShellArg self} ;
      ) || XC="$(( XC + 0x02 ))"

      printf '\n# Check linting ################################################\n'
      (
        statix check -c ${import ../lint/config.nix inputs} -- ${lib.escapeShellArg self} ;
      ) || XC="$(( XC + 0x04 ))"

      printf '\n# Check vulnerabilities ########################################\n'
      (
        printf '%s\n' \
          ${builtins.placeholder "out"} \
          ${builtins.concatStringsSep " "
            (builtins.map
              (app: builtins.head (builtins.match "(/.*)/bin/[^/]+" app.program))
              (builtins.attrValues
                (builtins.removeAttrs
                  self.apps.${system}
                  [ (builtins.baseNameOf ./.) ]
                )
              )
            )
          } \
          ${lib.optionalString (self ? devShells)
            (builtins.concatStringsSep " " (builtins.attrValues self.devShells.${system}))
          } \
          ${lib.optionalString (self ? packages)
            (builtins.concatStringsSep " " (builtins.attrValues self.packages.${system}))
          } \
        | awk '!x[$0]++' | xargs -r vulnix ;
      ) || XC="$(( XC + 0x08 ))"

      printf '\n\n# Finished #####################################################\n'
      printf '\x1B[1;%dmXC: 0x%02X\x1B[0m\n' \
        "$([ "$XC" -eq 0 ] && printf 32 || printf 31)" \
        "$XC"
      exit $XC
    '';
  };
}
