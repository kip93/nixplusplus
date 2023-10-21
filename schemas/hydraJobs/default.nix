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

{ nixpkgs, ... } @ _inputs:
{
  version = 1;
  doc = ''
    The `hydraJobs` flake output defines derivations to be built by the Hydra
    continuous integration system.
  '';
  inventory = output: {
    children = builtins.mapAttrs
      (_: category: {
        children = builtins.mapAttrs
          (name: jobset:
            let
              localSystem = builtins.head (nixpkgs.lib.splitString "." name);
              crossSystem = nixpkgs.lib.removePrefix "${localSystem}." name;

            in
            {
              forSystems = [ localSystem ];
              children = builtins.mapAttrs
                (_: job: {
                  what = "Hydra CI job (${
                    if localSystem == crossSystem then
                      "natively compiled on ${localSystem}"
                    else
                      "cross compiled on ${localSystem} for ${crossSystem}"
                  })";
                  derivation = job;
                })
                jobset
              ;
            }
          )
          category
        ;
      })
      output
    ;
  };
}
