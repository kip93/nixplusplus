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

# This lists all ports in a single file, to make it visible if something is
# trying to use the same ports.

# Should keep to conventions whenever it makes sense
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers

# For internal ports, they should be in the range [16000-17000) range and taken
# up on an incremental order as needed (this range was chosen just because it's
# a large enough range with no officially taken ports and no very important
# looking unofficial ones).
{
  ssh = {
    endlessh = 22;
    openssh = 222;
    stats = 16000;
  };
}
