{
  inputs.npp.url = "git+ssh://git.kip93.net/nix++";
  outputs = { npp, ... }: npp.lib.import.asCrossConfig ./config;
}
