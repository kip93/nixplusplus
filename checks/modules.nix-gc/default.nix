# This file is part of Nix++.
# Copyright (C) 2023 Leandro Emmanuel Reina Kiperman.
#
# Nix++ is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# Nix++ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

{ pkgs, self, ... } @ _args:
pkgs.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes =
    let
      common = { pkgs, ... }: {
        imports = with self.nixosModules; [ nix-gc ];
        virtualisation.graphics = false;
        virtualisation.additionalPaths = with pkgs; [ hello ];
        npp.nix-gc = { schedule = "@0"; };
      };

    in
    {
      machine1 = { imports = [ common ]; npp.nix-gc = { }; };
      machine2 = { imports = [ common ]; npp.nix-gc = { last = 10; }; };
      machine3 = { imports = [ common ]; npp.nix-gc = { days = 10; }; };
      machine4 = { imports = [ common ]; npp.nix-gc = { last = 0; days = 0; }; };
    };

  testScript = with pkgs; ''
    start_all()
    for machine in machines:
      for _ in range(50):
        machine.succeed("nix-env -i ${hello}")
        machine.succeed("nix-env -e hello")
        machine.succeed("date -s 'now + 1 days'")

      machine.succeed("mkdir -p /nix/var/nix/gcroots/auto/{foo,bar}")
      machine.succeed("ln -sf /dev/null /nix/var/nix/gcroots/auto/foo/bar")
      machine.succeed("ln -sf /dev/null /nix/var/nix/gcroots/auto/bar/foo")

      machine.systemctl("start npp_nix-gc.service")

    machine1.succeed("[ $(nix-env --list-generations | wc -l) -eq 54 ]")
    machine2.succeed("[ $(nix-env --list-generations | wc -l) -eq 54 ]")
    machine3.succeed("[ $(nix-env --list-generations | wc -l) -eq 18 ]")
    machine4.succeed("[ $(nix-env --list-generations | wc -l) -eq 1 ]")

    machine1.succeed("[ -e ${hello} ]")
    machine2.succeed("[ -e ${hello} ]")
    machine3.succeed("[ -e ${hello} ]")
    machine4.succeed("[ ! -e ${hello} ]")

    for machine in machines:
      machine.succeed("[ $(ls /nix/var/nix/gcroots/auto/ | wc -l) -eq 0 ]")

    for machine in machines:
      machine.shutdown()
  '';

  meta.timeout = 180;
}
