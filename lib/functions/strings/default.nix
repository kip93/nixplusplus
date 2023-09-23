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

{ nixpkgs, ... } @ _inputs: rec {
  # Create a string representation of a value of unknown type.
  # Values are evaluated shallowly.
  toString = _toString 1;

  # Create a string representation of a value of unknown type.
  # Values are evaluated deeply, potentially causing infinite recursion errors.
  toDeepString = _toString null;

  # Create a string representation of a value of unknown type.
  # Evaluate recursively N times, if N is not null. Otherwise, evaluate
  # infinitely.
  _toString = depth: value:
    let
      # https://nixos.org/manual/nix/stable/language/builtins.html#builtins-typeOf
      type = builtins.typeOf value;
    in
    if builtins.any (x: x == type) [ "float" "int" "path" ] then
      builtins.toString value
    else if type == "bool" then
      nixpkgs.lib.boolToString value
    else if type == "string" then
      nixpkgs.lib.strings.escapeNixString value
    else if type == "null" then
      "null"
    else if type == "list" then
      "[${
        builtins.foldl'
          (x: y: "${x}${y} ")
          " "
          (builtins.map
            (_toString (if depth != null then depth - 1 else null))
            value
          )
      }]"
    else if type == "set" then
      if builtins.hasAttr "__toString" value then
        value.__toString
      else if builtins.hasAttr "outPath" value then
        value.outPath
      else if depth == null || depth > 0 then
        "{${
          builtins.foldl'
            (x: y: "${x}${y} ")
            " "
            (nixpkgs.lib.attrsets.mapAttrsToList
              (name: value:
                "${
                  nixpkgs.lib.strings.escapeNixIdentifier name
                } = ${
                  _toString (if depth != null then depth - 1 else null) value
                };"
              )
              value
            )
        }}"
      else
        "{ ... }"
    else if type == "lambda" then
      "lambda"
    else
      abort "Unknown type: ${type}"
  ;
}
