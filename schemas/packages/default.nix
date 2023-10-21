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

{ nixpkgs, self, ... } @ _inputs:
{
  version = 1;
  doc = ''
    The `packages` flake output is a collection of packages that can be installed
    using `nix profile install`.
  '';
  inventory = output: {
    children = builtins.mapAttrs
      (localSystem: packages: {
        forSystems = [ localSystem ];
        children = (builtins.mapAttrs
          (_: derivation: {
            what = "Derivation for (natively compiled on ${localSystem})";
            inherit derivation;
          })
          (nixpkgs.lib.filterAttrs
            (name: _:
              (builtins.all (system: name != system) self.lib.supportedSystems)
                && (!nixpkgs.lib.hasPrefix "_" name)
            )
            packages
          )
        ) // (builtins.listToAttrs (builtins.map
          (crossSystem: {
            name = crossSystem;
            value = {
              children = builtins.mapAttrs
                (_: derivation: {
                  what = "Derivation (${
                    if localSystem == crossSystem then
                      "natively compiled on ${localSystem}"
                    else
                      "cross compiled on ${localSystem} for ${crossSystem}"
                  })";
                  inherit derivation;
                })
                (nixpkgs.lib.filterAttrs
                  (name: _: !nixpkgs.lib.hasPrefix "_" name)
                  packages.${crossSystem}.passthru
                )
              ;
            };
          })
          (builtins.filter
            (name:
              builtins.any (system: name == system)
                self.lib.supportedSystems
            )
            (builtins.attrNames packages)
          )
        ));
      })
      output
    ;
  };
}
