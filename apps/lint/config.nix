{ pkgs, ... } @ args:
with pkgs;
writeText "statix-config" ''
  disabled = [
    'redundant_pattern_bind',
  ]
  nix_version = '${nix.version}'
''
