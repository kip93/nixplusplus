{ nixpkgs, system, ... } @ inputs:
with nixpkgs.legacyPackages.${system};
writeText "statix-config" ''
  disabled = [
    'redundant_pattern_bind',
  ]
  nix_version = '${nix.version}'
''
