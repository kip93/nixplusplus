{ self, ... } @ inputs:
{
  # A collection of flakes, taken from the inputs of this flake. Useful for
  # overriding NixOS default ones.
  flakes.registry = (builtins.removeAttrs inputs [ "self" ]) // { nixplusplus = self; };
}
