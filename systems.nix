let
  fun = import ./lib/systems/default.nix;
in
(fun (builtins.functionArgs fun)).supportedSystems
