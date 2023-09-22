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

{ self, ... } @ inputs:
let
  ports = (import ../ports.nix).ssh;

in
{
  # SSH server
  services.openssh = {
    enable = true;
    ports = [ ports.openssh ];
    openFirewall = true;
    settings = {
      # No password
      ChallengeResponseAuthentication = self.lib.mkStrict "no";
      PasswordAuthentication = self.lib.mkStrict false;
      PermitRootLogin = self.lib.mkStrict "no";
      UsePAM = self.lib.mkStrict "no";

      # Only keys
      AuthenticationMethods = self.lib.mkStrict "publickey";
      PubkeyAuthentication = self.lib.mkStrict "yes";

      # Kill inactive sessions
      ClientAliveCountMax = 5;
      ClientAliveInterval = 60;
    };
  };

  # Tarpit
  services.endlessh-go = {
    enable = true;
    port = ports.endlessh;
    openFirewall = true;
    prometheus = { enable = true; port = ports.stats; };
  };

  # Watchdog
  services.fail2ban = {
    enable = true;
    # Be a bit more lenient by default (not much of an issue without password
    # auths).
    maxretry = 20;
    bantime = null; # Ban forever
  };
}
