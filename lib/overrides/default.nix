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
  # Create equivalents to nixpkgs override functions, but with a just ever so
  # slightly different value, so that our values and those of nixpkgs have
  # a clearer hirarchy.
  inherit (nixpkgs.lib) mkOverride;
  # Our defaults are higher priority than that of nixpkgs.
  mkDefault = mkOverride 999; # nixpkgs set 1000
  # Let user defined forced values take priority over ours.
  mkForce = mkOverride 51; # nixpkgs sets 50
  # Ignore any user configurations and set the value we ask.
  mkStrict = mkOverride 0; # No nixpkgs equivalent.
}
