{ nixpkgs, self, system, ... } @ args:
nixpkgs.legacyPackages.${system}.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes = {
    machine = { pkgs, ... }: {
      virtualisation.graphics = false;
      virtualisation.additionalPaths = with pkgs; [ hello ];
      environment.systemPackages = with self.packages.${system}; [ nix-gc ];
    };
  };

  testScript = ''
    machine.start()

    machine.succeed("nix-gc -u")
    machine.fail("nix-gc 0 0")

    for _ in range(50):
      machine.succeed("nix-env -i ${nixpkgs.legacyPackages.${system}.hello}")
      machine.succeed("nix-env -e hello")
      machine.succeed("date -s 'now + 1 days'")

    machine.succeed("[ -e ${nixpkgs.legacyPackages.${system}.hello} ]")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 100 ]")
    machine.succeed("nix-gc -l 99")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 100 ]")
    machine.succeed("nix-gc -d 101")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 100 ]")
    machine.succeed("nix-gc -u")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 54 ]")
    machine.succeed("nix-gc -u -d10")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 18 ]")
    machine.succeed("date -s 'now + 1 years'")
    machine.succeed("nix-gc -u")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 6 ]")
    machine.succeed("[ -e ${nixpkgs.legacyPackages.${system}.hello} ]")
    machine.succeed("nix-gc -l0 -d0")
    machine.succeed("[ ! -e ${nixpkgs.legacyPackages.${system}.hello} ]")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 1 ]")

    machine.shutdown()
  '';

  meta.timeout = 120;
}
