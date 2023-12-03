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
let
  validIPv4s = [
    "255.255.255.255"
    "192.168.1.1"
    "127.0.0.1"
    "0.0.0.0"
    "1.1.1.1"
    "1.1.1"
    "1.1"
  ];
  validIPv6s = [
    "0000:1111:2222:3333:4444:5555:192.168.1.1"
    "0000:1111:2222:3333:4444:5555:6666:7777"
    "2001:db8:c0a8:101::"
    "::ffff:c0a8:101"
    "f:f:f:f:f:f:f:f"
    "::ABCD:EF"
    "::1"
    "::"
  ];
  invalidIPv4s = [
    "256.256.256.256"
    "1.1.1.1.1"
    "1.0.0.0."
    "01.0.0.0"
    " 1.0.0.0"
    "1.0.0.0 "
    "X.X.X.X"
    "1..1"
    "1"
  ];
  invalidIPv6s = [
    "0000:1111:2222:3333:4444:5555:6666:7777:8888"
    "0000:1111:2222:3333:4444:5555:1.1"
    "::00000"
    "::1::1"
    "::1.1"
    ":::1"
    " ::1"
    "::1 "
    ":::"
    "::G"
  ];

in
pkgs.testers.nixTest {
  name = builtins.baseNameOf ./.;
  checks = {
    true = {
      expr = self.lib.strings.toString true;
      expected = "true";
    };
    false = {
      expr = self.lib.strings.toString false;
      expected = "false";
    };

    float = {
      expr = self.lib.strings.toString 1.2;
      expected = "1.200000";
    };
    int = {
      expr = self.lib.strings.toString 1;
      expected = "1";
    };

    path = {
      expr = self.lib.strings.toString /foo/bar;
      expected = "/foo/bar";
    };
    string = {
      expr = self.lib.strings.toString "foo";
      expected = ''"foo"'';
    };

    null = {
      expr = self.lib.strings.toString null;
      expected = "null";
    };

    lambda = {
      expr = self.lib.strings.toString (_: null);
      expected = "lambda";
    };

    emptyList = {
      expr = self.lib.strings.toString [ ];
      expected = "[ ]";
    };
    shallowList = {
      expr = self.lib.strings.toString [{ }];
      expected = "[ { ... } ]";
    };
    deepList = {
      expr = self.lib.strings.toDeepString [ [ [ 1 2 3 ] ] ];
      expected = "[ [ [ 1 2 3 ] ] ]";
    };

    emptySet = {
      expr = self.lib.strings.toString { };
      expected = "{ }";
    };
    shallowSet = {
      expr = self.lib.strings.toString { a.b.c = [ 1 ]; };
      expected = "{ a = { ... }; }";
    };
    deepSet = {
      expr = self.lib.strings.toDeepString { a.b.c = [ 1 ]; };
      expected = "{ a = { b = { c = [ 1 ]; }; }; }";
    };
    setWithString = {
      expr = self.lib.strings.toString { __toString = "foo"; };
      expected = "foo";
    };
    setWithOutPath = {
      expr = self.lib.strings.toString { outPath = "/foo"; };
      expected = "/foo";
    };

    validIPv4s = {
      expr = builtins.all self.lib.strings.isValidIPv4 validIPv4s;
      expected = true;
    };

    validIPv6s = {
      expr = builtins.all self.lib.strings.isValidIPv6 validIPv6s;
      expected = true;
    };

    validIPs = {
      expr = builtins.all self.lib.strings.isValidIP (validIPv4s ++ validIPv6s);
      expected = true;
    };

    invalidIPv4s = {
      expr = builtins.any self.lib.strings.isValidIPv4 (invalidIPv4s ++ validIPv6s);
      expected = false;
    };

    invalidIPv6s = {
      expr = builtins.any self.lib.strings.isValidIPv6 (invalidIPv6s ++ validIPv4s);
      expected = false;
    };

    invalidIPs = {
      expr = builtins.any self.lib.strings.isValidIP (invalidIPv4s ++ invalidIPv6s);
      expected = false;
    };
  };
}
