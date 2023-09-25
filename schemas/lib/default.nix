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
let
  # Cases that have special handling.
  exceptions = {
    flakes.registry._apply = flakes: {
      what = "An attrset of flakes";
      children = builtins.mapAttrs
        (_: _: { what = "flake"; })
        flakes
      ;
    };

    meta = {
      _apply = metadata: {
        what = "Metadata for this flake";
      } // recurse metadata [ "meta" ];
      license._apply = _: {
        what = "GPLv3+ license";
      };
      maintainers._apply = _: {
        what = "List of this flake's maintainers";
      };
    };

    pkgs._apply = allPkgs: {
      what = "Cross-compiled nixpkgs with overlays applied";
      children = builtins.mapAttrs
        (localSystem: crossPkgs: {
          children = builtins.mapAttrs
            (crossSystem: _: {
              what = "nixpkgs (${
                if localSystem == crossSystem then
                  "natively compiled on ${localSystem}"
                else
                  "cross compiled on ${localSystem} for ${crossSystem}"
              })";
            })
            crossPkgs
          ;
        })
        allPkgs
      ;
    };

    supportedSystems._apply = _: {
      what = "A list all of this flake's supported systems";
    };
    supportedSystems' = {
      darwin._apply = _: {
        what = "A list of this flake's supported Darwin systems";
      };
      linux._apply = _: {
        what = "A list of this flake's supported Linux systems";
      };
    };
  };

  recurse = attrs: path: {
    children = builtins.mapAttrs
      (name: value:
        let
          newPath = path ++ [ name ];

        in
        # Catch exceptions
        if nixpkgs.lib.hasAttrByPath (newPath ++ [ "_apply" ]) exceptions then
          (nixpkgs.lib.getAttrFromPath newPath exceptions)._apply value

        # Recurse into attrset
        else if builtins.isAttrs value then
          recurse value newPath

        # Leaf value
        else {
          what = builtins.typeOf value;
        }
      )
      # Filter "hidden" entries (that start with underscore)
      (nixpkgs.lib.filterAttrs
        (name: _: !nixpkgs.lib.hasPrefix "_" name)
        attrs
      )
    ;
  };

in
{
  version = 1;
  doc = ''
    The `lib` flake output defines arbitary Nix expressions.
  '';
  inventory = output: recurse output [ ];
}
