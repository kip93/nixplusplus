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

{ self, ... } @ _inputs:
{ config, lib, pkgs, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./..};
  hosts = [
    (lib.removePrefix "www." cfg.url)
  ] ++ (lib.optional (!self.lib.strings.isValidIP cfg.url)
    "www.${lib.removePrefix "www." cfg.url}"
  );

in
{
  config = {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    security.acme = lib.optionalAttrs (cfg.useACME && cfg.email != null) {
      certs.${cfg.url} = { inherit (cfg) email; };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        npp_hydra_https = {
          serverName = cfg.url;
          serverAliases = [ ];
          enableACME = cfg.useACME;
          ${if !cfg.useACME then "sslCertificate" else null} = "/var/lib/npp/hydra.cert";
          ${if !cfg.useACME then "sslCertificateKey" else null} = "/var/lib/npp/hydra.key";
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

    networking.hosts = { "127.0.0.1" = hosts; "::1" = hosts; };
    system.activationScripts.npp_hydra_cert = lib.optionalString (!cfg.useACME) ''
      (
        set -eu
        export PATH=${with pkgs; lib.escapeShellArg (lib.makeBinPath [
          coreutils
          openssl
        ])}

        if [ ! -f /var/lib/npp/hydra.cert ] || [ ! -f /var/lib/npp/hydra.key ] ; then
          mkdir -p /var/lib/npp
          rm -rf /var/lib/npp/hydra.cert /var/lib/npp/hydra.key

          openssl req 2>/dev/null \
            -newkey rsa:4096 -x509 -sha256 -nodes \
            -config ${pkgs.writeText "openssl-hydra.conf" ''
              [req]
              prompt = no
              distinguished_name = req_distinguished_name
              req_extensions = v3_req
              [req_distinguished_name]
              CN = ${cfg.url}
              ${lib.optionalString (cfg.email != null) ''
                emailAddress = ${cfg.email}
              ''}
              [v3_req]
              keyUsage = keyEncipherment, dataEncipherment
              extendedKeyUsage = serverAuth
              subjectAltName = @alt_names
              [alt_names]
              ${builtins.concatStringsSep "" (builtins.map
                ({ i, elem }: "DNS.${toString i} = ${elem}\n")
                (builtins.genList
                  (i: { i = i + 1; elem = builtins.elemAt hosts i; })
                  (builtins.length hosts)
                )
              )}
            ''} \
            -days 999999 \
            -out /var/lib/npp/hydra.cert \
            -keyout /var/lib/npp/hydra.key

          openssl x509 \
            -in /var/lib/npp/hydra.cert \
            -noout -text -certopt no_serial,no_issuer,no_pubkey,no_sigdump

          chown ${with config.services.nginx; "${user}:${group}"} /var/lib/npp/hydra.*

          mkdir -p /run/nixos
          printf 'nginx.service\n' >>/run/nixos/activation-restart-list
        fi
      )
    '';
  };
}
