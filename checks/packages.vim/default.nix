{ nixpkgs, self, system, ... } @ args:
nixpkgs.legacyPackages.${system}.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes = {
    machine = { pkgs, ... }: {
      virtualisation.graphics = false;
      environment.systemPackages = with self.packages.${system}; [ vim ];
    };
  };

  testScript = ''
    machine.start()

    machine.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
    machine.succeed('[ "$(realpath "$(which v)")"    == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
    machine.succeed('[ "$(realpath "$(which vi)")"   == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
    machine.succeed('[ "$(realpath "$(which vim)")"  == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
    machine.succeed('[ "$(realpath "$(which nvim)")" == "$(realpath "${self.packages.${system}.vim}/bin/nvim")" ]')
    machine.succeed("v -es")

    machine.shutdown()
  '';

  meta.timeout = 120;
}
