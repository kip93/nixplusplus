{ self, ... } @ inputs:
{ flakes.registry = (builtins.removeAttrs inputs [ "self" ]) // { nixplusplus = self; }; }
