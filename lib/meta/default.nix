{ self, ... } @ inputs:
{
  # Meta attributes.
  meta = rec {
    homepage = "git+ssh://git.kip93.net/nix++";
    maintainer = {
      name = "Leandro Emmanuel Reina Kiperman";
      email = "leandro@kip93.net";
      github = "kip93";
    };
    maintainers = [ maintainer ];
    license = with self.lib.licenses; [ gpl3 ];
  };
}
