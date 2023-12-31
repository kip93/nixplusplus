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

{ flake-schemas, self, ... } @ inputs:
(self.lib.import.asSchemas' {
  path = ./.;
  apply = _: schema: schema inputs;
}) // {
  inherit (flake-schemas.schemas)
    devShells
    checks
    # hydraJobs # Reimplemented to avoid nesting into cross compiled jobs
    nixosConfigurations
    nixosModules
    overlays
    # packages # We have a superset that also allows for cross-compilation
    schemas
    ;
}
