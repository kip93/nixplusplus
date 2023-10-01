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

{ ... } @ _inputs:
{ config, lib, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./..};

in
{
  config = {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    security.acme = lib.optionalAttrs (cfg.email != null) {
      certs.${cfg.url} = { inherit (cfg) email; };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        npp_hydra_https = {
          serverName = cfg.url;
          serverAliases = [ ];
          enableACME = true;
          onlySSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}/";
            extraConfig = ''
              add_header        Front-End-Https    on;
              proxy_set_header  Host               $host;
              proxy_set_header  X-Real-IP          $remote_addr;
              proxy_set_header  X-Forwarded-For    $proxy_add_x_forwarded_for;
              proxy_set_header  X-Forwarded-Proto  $scheme;
              proxy_set_header  X-Forwarded-Port   443;
              proxy_redirect                       off;
            '';
          };
        };
        npp_hydra_http = {
          inherit (config.services.nginx.virtualHosts.npp_hydra_https)
            serverName
            serverAliases
            enableACME
            ;
          listen = [
            { addr = "0.0.0.0"; port = 80; }
            { addr = "[::]"; port = 80; }
          ];
          locations."/".extraConfig = "return 301 https://$host$request_uri ;";
        };
      };
    };
  };
}
