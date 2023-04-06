{ flake-utils, nixpkgs, system, statix, ... } @ inputs:
with nixpkgs.legacyPackages.${system};
flake-utils.lib.mkApp {
  drv = writeShellApplication {
    name = builtins.baseNameOf ./.;
    runtimeInputs = [
      coreutils
      findutils
      statix.defaultPackage.${system}
    ];
    text = ''
      printf '%s\n' "$@" \
      | xargs -rL1 statix check -c ${import ./config.nix inputs} --
    '';
  };
}