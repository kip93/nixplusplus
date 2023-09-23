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

{ nixpkgs, npppkgs, pkgs, ... } @ _args:
pkgs.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes = {
    machine = { pkgs, ... }: {
      virtualisation.graphics = false;
      virtualisation.additionalPaths = with pkgs; [ hello ];
      environment.systemPackages = with npppkgs; [ nix-gc ];
      nix = {
        settings = {
          experimental-features = [ "nix-command" "flakes" ];
          flake-registry = pkgs.writeText "flake-registry.json" "{flakes=[],version=2}";
        };
        registry.nixpkgs.flake = nixpkgs;
      };
    };
  };

  testScript = with pkgs; ''
    machine.start()

    machine.succeed("mkdir -p /nix/var/nix/gcroots/auto/{foo,bar}")
    machine.succeed("ln -sf /dev/null /nix/var/nix/gcroots/auto/foo/bar")
    machine.succeed("ln -sf /dev/null /nix/var/nix/gcroots/auto/bar/foo")

    machine.succeed("nix-gc -u")
    machine.fail("nix-gc 0 0")

    for _ in range(50):
      machine.succeed("nix profile install nixpkgs#hello")
      machine.succeed("nix profile remove ${hello}")
      machine.succeed("date -s 'now + 1 days'")

    machine.succeed("[ -e ${hello} ]")
    machine.succeed("[ $(ls /nix/var/nix/gcroots/auto/ | wc -l) -ne 0 ]")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 100 ]")

    machine.succeed("nix-gc -ul 99")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 100 ]")

    machine.succeed("nix-gc -ud 101")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 100 ]")

    machine.succeed("nix-gc -u")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 54 ]")

    machine.succeed("nix-gc -u -d10")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 18 ]")

    machine.succeed("date -s 'now + 1 years'")
    machine.succeed("nix-gc -u")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 6 ]")

    machine.succeed("nix-gc")
    machine.succeed("[ -e ${hello} ]")
    machine.succeed("[ $(ls /nix/var/nix/gcroots/auto/ | wc -l) -eq 0 ]")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 6 ]")

    machine.succeed("nix-gc -l0 -d0")
    machine.succeed("[ ! -e ${hello} ]")
    machine.succeed("[ $(nix-env --list-generations | wc -l) -eq 1 ]")

    machine.shutdown()
  '';

  meta.timeout = 120;
}
