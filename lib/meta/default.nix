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

{ nixpkgs, ... } @ inputs:
{
  # Meta attributes.
  meta = rec {
    homepage = "git+ssh://git.kip93.net/nix++";
    maintainer = {
      name = "Leandro Emmanuel Reina Kiperman";
      email = "leandro@kip93.net";
      github = "kip93";
    };
    maintainers = [ maintainer ];
    license = with nixpkgs.lib.licenses; [ gpl3Plus ];
  };
}