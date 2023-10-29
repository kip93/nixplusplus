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

{ self, ... } @ _inputs:
final: prev: with final; {
  # An analogous to pkgs.testers.runNixOSTest, but for nix expressions instead
  # of derivations.
  # Basically a wrapper for pkgs.lib.runTests, made to work for nix flake
  # checks. Just like runNixOSTest, it runs a test and then creates an empty
  # derivation as a placeholder. Unlike runNixOSTest, this runs at evaluation
  # time, not build time; therefore this will run first, and will fail fast.
  testers = prev.testers // {
    nixTest = { name, checks }:
      let
        failed = builtins.listToAttrs
          (builtins.map
            (result: {
              name = builtins.substring 4 (builtins.stringLength result.name)
                result.name
              ;
              value = { inherit (result) result expected; };
            })
            (lib.runTests (lib.mapAttrs'
              (name: value: {
                name = "test${name}";
                inherit value;
              })
              checks
            ))
          )
        ;
      in
      assert lib.asserts.assertMsg
        (builtins.length (builtins.attrNames failed) == 0)
        "[ ${name} ] Tests failed:${builtins.foldl'
          (x: name:
            let
              failure = failed.${name};
              actual = self.lib.strings.toDeepString failure.result;
              expected = self.lib.strings.toDeepString failure.expected;
            in
            "${x}\n* ${name}\n  ${actual} != ${expected}"
          )
          ""
          (builtins.attrNames failed)
        }"
      ; runCommand name { } "mkdir -p $out"
    ;
  };

  # The complement of pkgsCross, pkgsBuildBuild, and pkgsHostTarget. Could be
  # called pkgsHostHostHost but that'd be a bit excesive.
  # See nixpkgs#253261
  pkgsNative = import final.path {
    config = pkgs.config or { };
    overlays = [
      (_: prev': {
        pkgsNative = prev'.pkgsNative or prev';
      })
    ] ++ (pkgs.overlays or [ ]);
    localSystem = pkgs.hostPlatform;
    crossSystem = null;
  };
}
