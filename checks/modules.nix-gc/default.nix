{ nixpkgs, self, system, ... } @ args:
nixpkgs.legacyPackages.${system}.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes =
    let
      common = { lib, pkgs, ... }: {
        imports = with self.nixosModules; [ nix-gc ];
        virtualisation.graphics = false;
        virtualisation.additionalPaths = with pkgs; [ hello ];

        nixplusplus.nix-gc = { schedule = "@0"; };
      };
    in
    {
      machine1 = { imports = [ common ]; nixplusplus.nix-gc = { }; };
      machine2 = { imports = [ common ]; nixplusplus.nix-gc = { last = 10; }; };
      machine3 = { imports = [ common ]; nixplusplus.nix-gc = { days = 10; }; };
      machine4 = { imports = [ common ]; nixplusplus.nix-gc = { last = 0; days = 0; }; };
    };

  testScript = ''
    start_all()
    for machine in machines:
      for _ in range(50):
        machine.succeed("nix-env -i ${nixpkgs.legacyPackages.${system}.hello}")
        machine.succeed("nix-env -e hello")
        machine.succeed("date -s 'now + 1 days'")

      machine.succeed("mkdir -p /nix/var/nix/gcroots/auto/{foo,bar}")
      machine.succeed("ln -sf /dev/null /nix/var/nix/gcroots/auto/foo/bar")
      machine.succeed("ln -sf /dev/null /nix/var/nix/gcroots/auto/bar/foo")

      machine.systemctl("start nixplusplus_nix-gc.service")

    machine1.succeed("[ $(nix-env --list-generations | wc -l) -eq 54 ]")
    machine2.succeed("[ $(nix-env --list-generations | wc -l) -eq 54 ]")
    machine3.succeed("[ $(nix-env --list-generations | wc -l) -eq 18 ]")
    machine4.succeed("[ $(nix-env --list-generations | wc -l) -eq 1 ]")

    machine1.succeed("[ -e ${nixpkgs.legacyPackages.${system}.hello} ]")
    machine2.succeed("[ -e ${nixpkgs.legacyPackages.${system}.hello} ]")
    machine3.succeed("[ -e ${nixpkgs.legacyPackages.${system}.hello} ]")
    machine4.succeed("[ ! -e ${nixpkgs.legacyPackages.${system}.hello} ]")

    for machine in machines:
      machine.succeed("[ $(ls /nix/var/nix/gcroots/auto/ | wc -l) -eq 0 ]")

    for machine in machines:
      machine.shutdown()
  '';

  meta.timeout = 180;
}
