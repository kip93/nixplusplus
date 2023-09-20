{
  inputs = {
    npp = {
      url = "git+ssh://git.kip93.net/nix++";
      inputs.systems.follows = "systems";
    };
    # Workaround for nix-systems#6 (hopefully will be fixed with nix#3978)
    systems = {
      url = "git+ssh://git.kip93.net/nix++?dir=systems.nix";
      flake = false;
    };
  };
  outputs = { npp, ... }: npp.lib.import.asCrossConfig ./config;
}
