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
pkgs.nixTest {
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

    empty_list = {
      expr = self.lib.strings.toString [ ];
      expected = "[ ]";
    };
    shallow_list = {
      expr = self.lib.strings.toString [{ }];
      expected = "[ { ... } ]";
    };
    deep_list = {
      expr = self.lib.strings.toDeepString [ [ [ 1 2 3 ] ] ];
      expected = "[ [ [ 1 2 3 ] ] ]";
    };

    empty_set = {
      expr = self.lib.strings.toString { };
      expected = "{ }";
    };
    shallow_set = {
      expr = self.lib.strings.toString { a.b.c = [ 1 ]; };
      expected = "{ a = { ... }; }";
    };
    deep_set = {
      expr = self.lib.strings.toDeepString { a.b.c = [ 1 ]; };
      expected = "{ a = { b = { c = [ 1 ]; }; }; }";
    };
    set_with_string = {
      expr = self.lib.strings.toString { __toString = "foo"; };
      expected = "foo";
    };
    set_with_out_path = {
      expr = self.lib.strings.toString { outPath = "/foo"; };
      expected = "/foo";
    };
  };
}
