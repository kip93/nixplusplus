{ pkgs, self, system, ... } @ args:
with self.packages.${system};
pkgs.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes = {
    machine1 = { pkgs, ... }: {
      virtualisation.graphics = false;
      environment.systemPackages = [ vim-minimal ];
    };
  } // (pkgs.lib.optionalAttrs (self.packages.${system} ? vim-full)) {
    machine2 = { pkgs, ... }: {
      virtualisation.graphics = false;
      environment.systemPackages = [ vim ];
    };
  };

  testScript = ''
    machine1.start()

    machine1.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${vim-minimal}/bin/nvim")" ]')
    machine1.succeed('[ "$(realpath "$(which vi)")"   == "$(realpath "${vim-minimal}/bin/nvim")" ]')
    machine1.succeed('[ "$(realpath "$(which vim)")"  == "$(realpath "${vim-minimal}/bin/nvim")" ]')
    machine1.succeed('[ "$(realpath "$(which nvim)")" == "$(realpath "${vim-minimal}/bin/nvim")" ]')
    machine1.succeed("v -es")

    machine1.shutdown()

    ${pkgs.lib.optionalString (self.packages.${system} ? vim-full) ''
      machine2.start()

      machine2.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${vim-full}/bin/nvim")" ]')
      machine2.succeed('[ "$(realpath "$(which vi)")"   == "$(realpath "${vim-full}/bin/nvim")" ]')
      machine2.succeed('[ "$(realpath "$(which vim)")"  == "$(realpath "${vim-full}/bin/nvim")" ]')
      machine2.succeed('[ "$(realpath "$(which nvim)")" == "$(realpath "${vim-full}/bin/nvim")" ]')
      machine2.succeed("v -es")

      machine2.shutdown()
    ''}
  '';

  meta.timeout = 120;
}
