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

    machine.succeed('[ "$(realpath "$(which vi)")"   == "${self.packages.${system}.vim}/bin/nvim" ]')
    machine.succeed('[ "$(realpath "$(which vim)")"  == "${self.packages.${system}.vim}/bin/nvim" ]')
    machine.succeed('[ "$(realpath "$(which nvim)")" == "${self.packages.${system}.vim}/bin/nvim" ]')
    machine.succeed("vim -es")

    machine.shutdown()
  '';

  meta.timeout = 120;
}
