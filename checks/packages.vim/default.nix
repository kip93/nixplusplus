{ nixpkgs, self, system, ... } @ args:
nixpkgs.legacyPackages.${system}.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes = {
    machine1 = { pkgs, ... }: {
      virtualisation.graphics = false;
      environment.systemPackages = with self.packages.${system}; [ vim-minimal ];
    };
  } // (self.lib.optionalAttrs (system != "armv7l-linux")) {
    machine2 = { pkgs, ... }: {
      virtualisation.graphics = false;
      environment.systemPackages = with self.packages.${system}; [ vim ];
    };
  };

  testScript = ''
    machine1.start()

    machine1.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${self.packages.${system}.vim-minimal}/bin/nvim")" ]')
    machine1.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${self.packages.${system}.vim-minimal}/bin/nvim")" ]')
    machine1.succeed('[ "$(realpath "$(which vi)")"   == "$(realpath "${self.packages.${system}.vim-minimal}/bin/nvim")" ]')
    machine1.succeed('[ "$(realpath "$(which vim)")"  == "$(realpath "${self.packages.${system}.vim-minimal}/bin/nvim")" ]')
    machine1.succeed('[ "$(realpath "$(which nvim)")" == "$(realpath "${self.packages.${system}.vim-minimal}/bin/nvim")" ]')
    machine1.succeed("v -es")

    machine1.shutdown()

    ${self.lib.optionalString (system != "armv7l-linux") ''
      machine2.start()

      machine2.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
      machine2.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
      machine2.succeed('[ "$(realpath "$(which vi)")"   == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
      machine2.succeed('[ "$(realpath "$(which vim)")"  == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
      machine2.succeed('[ "$(realpath "$(which nvim)")" == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
      machine2.succeed("v -es")

      machine2.shutdown()
    ''}
  '';

  meta.timeout = 120;
}
