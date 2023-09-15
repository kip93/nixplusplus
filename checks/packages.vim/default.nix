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

{ npppkgs, pkgs, self, system, ... } @ args:
with npppkgs;
pkgs.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes = {
    machine1 = { pkgs, ... }: {
      virtualisation.graphics = false;
      environment.systemPackages = [ vim-minimal ];
    };
  } // (pkgs.lib.optionalAttrs (npppkgs ? vim-full)) {
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

    ${pkgs.lib.optionalString (npppkgs ? vim-full) ''
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
