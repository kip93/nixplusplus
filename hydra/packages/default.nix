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
# Filter out meta packages
with nixpkgs.lib;
builtins.mapAttrs (_: v: filterAttrs (k: _: !hasPrefix "_" k) v.passthru)
{
  # Cherry picked scenarios, since I have only a subset of "supported systems"
  # as hydra builders.

  # Native compilation
  "x86_64-linux" = self.packages.x86_64-linux.x86_64-linux;
  "aarch64-linux" = self.packages.aarch64-linux.aarch64-linux;
  "armv7l-linux" = self.packages.armv7l-linux.armv7l-linux;

  # Cross compilation
  "x86_64-linux.aarch64-linux" = self.packages.x86_64-linux.aarch64-linux;
  "x86_64-linux.armv7l-linux" = self.packages.x86_64-linux.armv7l-linux;
  "x86_64-linux.armv6l-linux" = self.packages.x86_64-linux.armv6l-linux;
  "aarch64-linux.armv7l-linux" = self.packages.aarch64-linux.armv7l-linux;
  "aarch64-linux.armv6l-linux" = self.packages.aarch64-linux.armv6l-linux;
  "armv7l-linux.armv6l-linux" = self.packages.armv7l-linux.armv6l-linux;
}
