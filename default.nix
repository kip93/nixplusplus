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

let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  inherit (lock.nodes) flake-compat;

  url = "https://github.com/edolstra/flake-compat/archive/${flake-compat.locked.rev}.tar.gz";
  sha256 = flake-compat.locked.narHash;

  flake = (import (fetchTarball { inherit url sha256; }) { src = ./.; }).defaultNix;

in
flake.packages.${builtins.currentSystem}.default.overrideAttrs (_: {
  passthru = flake.packages.${builtins.currentSystem};
})
