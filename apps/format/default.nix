{ flake-utils, nixpkgs, system, nixpkgs-fmt, ... } @ inputs:
with nixpkgs.legacyPackages.${system};
flake-utils.lib.mkApp {
  drv = writeShellApplication {
    name = builtins.baseNameOf ./.;
    runtimeInputs = [
      nixpkgs-fmt.defaultPackage.${system}
    ];
    text = ''
      nixpkgs-fmt -- "''${@:-.}"
    '';
  };
}
