# This file is part of Nix++.
# Copyright (C) 2024 Leandro Emmanuel Reina Kiperman.
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
{ config, lib, pkgs, ... }:
let
  ports = (import ../../../ports.nix).netdata;

in
{
  config.services = {
    # https://nixos.wiki/wiki/Netdata
    netdata = {
      enable = true;
      package = pkgs.pkgsNative.netdata; # Netdata does not cross-compile
      config = {
        global = {
          "debug log" = "none";
          "access log" = "none";
          "error log" = "none";

          "page cache size" = 32;
        };

        # https://netdata-storage-calculator.herokuapp.com/
        db = {
          "mode" = "dbengine";
          "storage tiers" = 3;
          "update every" = 1;
          "dbengine multihost disk space MB" = 128;
          "dbengine page cache size MB" = 32;
          "dbengine tier 1 update every iterations" = 60;
          "dbengine tier 1 multihost disk space MB" = 256;
          "dbengine tier 1 page cache size MB" = 32;
          "dbengine tier 2 update every iterations" = 60;
          "dbengine tier 2 multihost disk space MB" = 512;
          "dbengine tier 2 page cache size MB" = 32;
        };

        web = {
          "mode" = "none";
        };

        ml = {
          "enabled" = "no";
        };

      } // lib.optionalAttrs config.services.nginx.enable {
        plugins = { "go.d" = "yes"; };
      };

      configDir = lib.optionalAttrs config.services.nginx.enable {
        "go.d/nginx.conf" = pkgs.writeText "netdata-nginx.conf" ''
          enabled: yes
          jobs:
            - name: nginx_status
              url: http://127.0.0.1:${toString ports.nginx}/status
        '';
      };
    };

    nginx.virtualHosts = lib.optionalAttrs (config.services.netdata.enable && config.services.nginx.enable) {
      npp_netdata_nginx_status = {
        serverName = "status.localhost";
        listen = [{
          addr = "localhost";
          port = ports.nginx;
        }];
        locations."= /status".extraConfig = "stub_status on ;";
        extraConfig = ''
          allow 127.0.0.0/8 ;
          deny all ;

          keepalive_timeout 0 ;
          access_log /dev/null combined ;
          error_log /dev/null crit ;
        '';
      };
    };
  };
}
