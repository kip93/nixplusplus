{ pkgs, ... } @ args:
with pkgs;
writeShellApplication {
  name = builtins.baseNameOf ./.;
  runtimeInputs = [
    nixpkgs-fmt
  ];
  text = ''
    nixpkgs-fmt -- "''${@:-.}"
  '';
}
