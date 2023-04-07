{ pkgs, ... } @ args:
with pkgs;
writeShellApplication {
  name = builtins.baseNameOf ./.;
  runtimeInputs = [
    coreutils
    findutils
    statix
  ];
  text = ''
    printf '%s\n' "''${@:-.}" \
    | xargs -rL1 statix check -c ${import ./config.nix args} --
  '';
}
