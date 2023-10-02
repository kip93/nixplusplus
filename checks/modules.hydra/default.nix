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

{ nixpkgs, pkgs, self, system, ... } @ _args:
let
  inherit (pkgs) lib;

  certs = import "${nixpkgs}/nixos/tests/common/acme/server/snakeoil-certs.nix";
  inherit (certs) domain;
  port = (import ../../modules/ports.nix).hydra;

in
pkgs.testers.runNixOSTest {
  name = builtins.baseNameOf ./.;

  nodes.server = { lib, ... }: {
    imports = with self.nixosModules; [ secrets hydra ];
    virtualisation = { memorySize = 2048; graphics = false; };
    environment.systemPackages = with pkgs; [ curl jq ];

    # Disable Let's encrypt and use hardcoded certs
    networking.hosts = { "127.0.0.1" = [ domain ]; "::1" = [ domain ]; };
    security.pki.certificateFiles = [ certs.ca.cert ];
    services.nginx.virtualHosts.npp_hydra_https = {
      enableACME = lib.mkForce false;
      sslCertificate = certs.${domain}.cert;
      sslCertificateKey = certs.${domain}.key;
    };

    # Bad security practice, but this is just a test.
    npp.secrets_key = "${../test.key}";
    npp.hydra = {
      url = domain;
      passwordFile = ./hydra.password.age;
      commands = [
        {
          command = "touch /tmp/glob-match";
        }
        {
          project = "test-project";
          jobset = "test-jobset";
          job = "test-job";
          command = "touch /tmp/noglob-match";
        }
      ];
    };
  };

  testScript = ''
    server.start()

    server.wait_for_unit("npp_configure-hydra-user.service")
    server.require_unit_state("postgresql.service")
    server.require_unit_state("hydra-init.service")
    server.wait_for_unit("hydra-server.service")
    server.require_unit_state("hydra-queue-runner.service")
    server.require_unit_state("hydra-evaluator.service")
    server.require_unit_state("hydra-notify.service")
    server.wait_for_open_port(${toString port})
    server.wait_for_unit("nginx.service")

    server.succeed("""
      curl -fsSe https://${domain} >&2 \\
        -H 'Accept: application/json' \\
        -H 'Content-Type: application/json' \\
        -c cookie_jar.txt \\
        -X POST https://${domain}/login \\
        -d ${lib.escapeShellArg (builtins.toJSON {
          username = "admin";
          password = "admin";
        })}
    """)

    server.succeed("""
      curl -fsSe https://${domain} >&2 \\
        -H 'Accept: application/json' \\
        -H 'Content-Type: application/json' \\
        -b cookie_jar.txt \\
        -X PUT https://${domain}/project/test-project \\
        -d ${lib.escapeShellArg (builtins.toJSON {
          displayname = "Test project";
          enabled = 1;
          hidden = 0;
        })}
    """)

    server.succeed("""
      curl -fsSe https://${domain} >&2 \\
        -H 'Accept: application/json' \\
        -H 'Content-Type: application/json' \\
        -b cookie_jar.txt \\
        -X PUT https://${domain}/jobset/test-project/test-jobset \\
        -d ${lib.escapeShellArg (builtins.toJSON {
          description = "Test jobset";
          enabled = 1;
          hidden = 0;
          checkinterval = 30;
          nixexprinput = "src";
          nixexprpath = "default.nix";
          keepnr = 1;
          emailoverride = "";
          inputs.src = {
            type = "path";
            value = "${pkgs.writeTextDir "default.nix" ''
              {
                test-job = builtins.derivation {
                  name = "test-job";
                  system = "${system}";
                  builder = "/bin/sh";
                  allowSubstitutes = false;
                  preferLocalBuild = true;
                  args = [ "-c" "echo ok >$out ; exit 0" ];
                };
              }
            ''}";
          };
        })}
    """)

    server.wait_until_succeeds("""
      curl -fsS >&2 \\
        -H 'Accept: application/json' \\
        -X GET https://${domain}/eval/1
    """)

    server.wait_until_succeeds("""
      curl -fsS >&2 \\
        -H 'Accept: application/json' \\
        -X GET https://${domain}/build/1
    """)

    server.wait_until_succeeds("""
      curl -fsS >&2 \\
        -H 'Accept: application/json' \\
        -X GET https://${domain}/build/1 \\
      | jq .buildstatus | xargs -r test 0 -eq
    """)

    server.wait_until_succeeds("""
      test -f /tmp/glob-match && test -f /tmp/noglob-match
    """)

    server.shutdown()
  '';

  meta.timeout = 180;
}
