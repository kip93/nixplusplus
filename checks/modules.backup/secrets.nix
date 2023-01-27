# EDITOR=vim nix run github:ryantm/agenix -- -i ../test.key -e <AGE_FILE>
let
  publicKeys = [ (builtins.readFile ../test.pub) ];
in
{
  "backup.password.age" = { inherit publicKeys; };
  "backup.sshconfig.age" = { inherit publicKeys; };
  "backup.sshkey.age" = { inherit publicKeys; };
}
