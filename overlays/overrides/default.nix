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

{ hydra, nix, ... } @ inputs:
final: prev:
let
  # Avoid infinite recursion by renaming flakes
  hydra' = hydra;
  nix' = nix;

in
let
  # A fake overlaid pkgs, to ensure that hydra uses it's own version of nix,
  # due to hydra#1182
  hydra_final = final // (hydra'.inputs.nix.overlays.default hydra_final prev);
  # Get the relevant bits out of the provided overlays
  inherit (hydra'.overlays.default hydra_final prev) hydra perlPackages;
  inherit (nix'.overlays.default final prev) lowdown-nix nix;

in
{
  # Expose the extracted packages into the overlay
  inherit lowdown-nix nix perlPackages;
  hydra_unstable = hydra;
}
