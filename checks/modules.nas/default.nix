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

{ pkgs, self, ... } @ _args:
let
  checkMount = checks: ''"""awk ${pkgs.lib.escapeShellArg
    "BEGIN { xc=1; } ${builtins.concatStringsSep " && " checks} { print; xc=0; } END { exit xc; }"
  } /proc/mounts >&2"""'';

in
pkgs.testers.runNixOSTest rec {
  name = builtins.baseNameOf ./.;

  defaults = {
    virtualisation.graphics = false;
  };
  nodes = {
    server = rec {
      imports = with self.nixosModules; [
        nas
        ({ config, ... }: {
          boot = {
            loader.timeout = 0;
            zfs = {
              devNodes = "/dev";
              forceImportAll = self.lib.mkStrict true;
              forceImportRoot = self.lib.mkStrict true;
            };
          };
          fileSystems = self.lib.mkStrict config.virtualisation.fileSystems;
          virtualisation = {
            memorySize = 2048; # 2G of RAM
            emptyDiskImages = [
              # RAIDZ1 1G usable / 1.5G raw
              512
              512
              512
              # Mirror 512M usable / 1G raw
              512
              512
            ];

            useBootLoader = true;
            mountHostNixStore = true;
          };
        })
        # TODO Get rid of this option
        ({ lib, ... }: { options.npp.nas._test = with lib; mkOption { type = types.bool; default = true; }; })
      ];

      system.build.test = builtins.concatStringsSep "\n" (builtins.map
        ({ configuration, ... }: configuration.system.build.test)
        (builtins.attrValues specialisation)
      );

      specialisation = rec {
        # Pool with no datasets
        test01.configuration = {
          npp.nas.datasets."pool0" = { };
          environment.systemPackages = with pkgs; [ gawk ];
          system.build.test =
            let
              test = ''
                server.succeed("zpool list pool0 >&2")
                server.succeed(${checkMount [ ''$1 == "pool0"'' ''$2 == "/mnt/pool0"'' ''$3 == "zfs"'' ]})
                server.succeed("test $(zfs get -Ho source exec pool0 | tee /dev/fd/2) == 'default'")
                server.succeed("test $(zfs get -Ho value  exec pool0 | tee /dev/fd/2) == 'on'")
              '';

            in
            ''
              server.succeed("zpool create pool0 raidz1 /dev/vd[b-d] >&2")
              server.succeed("/tmp/specialisation/test01/bin/switch-to-configuration boot >&2")
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
            ''
          ;
        };
        # Add property
        test02.configuration = {
          npp.nas.datasets."pool0" = {
            properties = {
              exec = "off";
            };
          };
          system.build.test =
            let
              test = ''
                server.succeed("test $(zfs get -Ho source exec pool0 | tee /dev/fd/2) == 'local'")
                server.succeed("test $(zfs get -Ho value  exec pool0 | tee /dev/fd/2) == 'off'")
              '';

            in
            ''
              server.succeed("/tmp/specialisation/test02/bin/switch-to-configuration switch >&2")
              ${test}
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
            ''
          ;
        };
        # Add dataset
        test03.configuration = {
          npp.nas.datasets = test02.configuration.npp.nas.datasets // {
            "pool0/compressed" = {
              properties = {
                compress = "lz4";
              };
            };
          };
          environment.systemPackages = with pkgs; [ gawk ];
          system.build.test =
            let
              test = ''
                server.succeed("zfs list pool0/compressed >&2")
                server.succeed(${checkMount [ ''$1 == "pool0/compressed"'' ''$2 == "/mnt/pool0/compressed"'' ''$3 == "zfs"'' ]})
                server.succeed('test "$(zfs get -Ho source exec     pool0/compressed | tee /dev/fd/2)" == "inherited from pool0"')
                server.succeed('test "$(zfs get -Ho value  exec     pool0/compressed | tee /dev/fd/2)" == "off"')
                server.succeed('test "$(zfs get -Ho source compress pool0/compressed | tee /dev/fd/2)" == "local"')
                server.succeed('test "$(zfs get -Ho value  compress pool0/compressed | tee /dev/fd/2)" == "lz4"')
              '';

            in
            ''
              server.succeed("/tmp/specialisation/test03/bin/switch-to-configuration switch >&2")
              ${test}
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
            ''
          ;
        };
        # Add missing boot pool
        test04.configuration = {
          # Allow recovering from failure of missing pool
          boot.initrd.postDeviceCommands = self.lib.mkFirst ''
            unset panicOnFail
            allowShell=1
          '';
          npp.nas.datasets = test03.configuration.npp.nas.datasets // {
            "pool1" = {
              mountPoint = "/var";
            };
          };
          environment.systemPackages = with pkgs; [ gawk ];
          system.build.test =
            let
              test = ''
                server.succeed("zpool list pool1 >&2")
                server.succeed(${checkMount [ ''$1 == "pool1"'' ''$2 == "/var"'' ''$3 == "zfs"'' ]})
              '';

            in
            ''
              server.succeed("/tmp/specialisation/test04/bin/switch-to-configuration boot >&2")
              server.shutdown()
              server.start()
              server.wait_for_console_text('importing root ZFS pool "pool1"')
              server.wait_for_console_text("cannot import 'pool1': no such pool available")
              server.wait_for_console_text("\[ nix\+\+ \] Setting up ZFS\.\.\.")
              server.wait_for_console_text("Missing pools:")
              server.wait_for_console_text(" \* pool1")
              server.wait_for_console_text("An error occurred in stage 1 of the boot process")
              server.wait_for_console_text("  i\) to launch an interactive shell")
              server.wait_for_console_text("  \*\) to ignore the error and continue")
              server.send_console("i\n")
              server.wait_for_console_text("Starting interactive shell...")
              server.wait_for_console_text("~ #")
              server.send_console("zpool create pool1 mirror /dev/vd[e-f] >&2\n")
              server.wait_for_console_text("~ #")
              server.send_console("exit\n")
              server.wait_for_unit("multi-user.target")
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
            ''
          ;
        };
        # Add boot dataset
        test05.configuration = {
          npp.nas.datasets = test04.configuration.npp.nas.datasets // {
            "pool1/lib" = { };
          };
          environment.systemPackages = with pkgs; [ gawk ];
          system.build.test =
            let
              test = ''
                server.succeed("zfs list pool1/lib >&2")
                server.succeed(${checkMount [ ''$1 == "pool1/lib"'' ''$2 == "/var/lib"'' ''$3 == "zfs"'' ]})
              '';

            in
            ''
              server.succeed("/tmp/specialisation/test05/bin/switch-to-configuration boot >&2")
              server.shutdown()
              server.start()
              server.wait_for_console_text("<<< NixOS Stage 1 >>>")
              server.wait_for_console_text("mounting pool1/lib on /var/lib")
              server.wait_for_console_text("<<< NixOS Stage 2 >>>")
              server.wait_for_unit("multi-user.target")
              ${test}
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
            ''
          ;
        };
        # Clean up datasets
        test06.configuration = {
          npp.nas.datasets = test02.configuration.npp.nas.datasets;
          system.build.test =
            let
              test = ''
                logs = server.succeed("""
                  journalctl _SYSTEMD_INVOCATION_ID=$( \
                    systemctl show --property=InvocationID --value npp_zfs-config.service \
                  ) | tee /dev/fd/2
                """)
                assert "Unmanaged datasets found:" not in logs
              '';

            in
            ''
              server.succeed("/tmp/specialisation/test06/bin/switch-to-configuration boot >&2")
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              logs = server.succeed("""
                journalctl _SYSTEMD_INVOCATION_ID=$( \
                  systemctl show --property=InvocationID --value npp_zfs-config.service \
                ) | tee /dev/fd/2
              """)
              assert "Unmanaged datasets found:" in logs
              assert " * pool0/compressed" in logs
              assert " * pool1" not in logs
              assert " * pool1/lib" not in logs
              server.succeed("zfs destroy -f pool0/compressed >&2")
              server.succeed("zpool import -f pool1 >&2 && zpool destroy -f pool1 >&2")
              server.succeed("systemctl restart npp_zfs-config.service >&2 && sleep 5")
              ${test}
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
            ''
          ;
        };
        # Remove properties
        test07.configuration = {
          npp.nas.datasets = test01.configuration.npp.nas.datasets;
          system.build.test =
            let
              test = ''
                server.succeed("test $(zfs get -Ho source exec pool0 | tee /dev/fd/2) == 'default'")
              '';

            in
            ''
              server.succeed("/tmp/specialisation/test07/bin/switch-to-configuration switch >&2")
              ${test}
              server.shutdown()
              server.start()
              server.wait_for_unit("multi-user.target")
              ${test}
            ''
          ;
        };
        # Add snapshots
        test08.configuration = {
          npp.nas.datasets."pool0" = test01.configuration.npp.nas.datasets."pool0" // {
            snapshots = { frequent = 5; hourly = 1; };
          };
          system.build.test = ''
            server.succeed("test $(zfs get -Ho value snapdir pool0 | tee /dev/fd/2) == 'hidden'")
            server.succeed("/tmp/specialisation/test08/bin/switch-to-configuration switch >&2")
            server.succeed("test $(zfs get -Ho value snapdir pool0 | tee /dev/fd/2) == 'visible'")
            server.succeed("systemctl start npp_zfs-snapshot.service && sleep 5")
            server.wait_until_succeeds("systemctl show npp_zfs-snapshot.service | grep -qxF ActiveState=inactive", timeout=10)
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | tee /dev/fd/2 | wc -l) -ge 2")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.frequent.' | tee /dev/fd/2 | wc -l) -ge 1")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.hourly.'   | tee /dev/fd/2 | wc -l) -eq 1")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.daily.'    | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.weekly.'   | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.monthly.'  | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.yearly.'   | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("systemctl start npp_zfs-snapshot.service && sleep 5")
            server.wait_until_succeeds("systemctl show npp_zfs-snapshot.service | grep -qxF ActiveState=inactive", timeout=10)
            server.succeed("systemctl start npp_zfs-snapshot.service && sleep 5")
            server.wait_until_succeeds("systemctl show npp_zfs-snapshot.service | grep -qxF ActiveState=inactive", timeout=10)
            server.succeed("systemctl start npp_zfs-snapshot.service && sleep 5")
            server.wait_until_succeeds("systemctl show npp_zfs-snapshot.service | grep -qxF ActiveState=inactive", timeout=10)
            server.succeed("systemctl start npp_zfs-snapshot.service && sleep 5")
            server.wait_until_succeeds("systemctl show npp_zfs-snapshot.service | grep -qxF ActiveState=inactive", timeout=10)
            server.succeed("systemctl start npp_zfs-snapshot.service && sleep 5")
            server.wait_until_succeeds("systemctl show npp_zfs-snapshot.service | grep -qxF ActiveState=inactive", timeout=10)
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | tee /dev/fd/2 | wc -l) -eq 6")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.frequent.' | tee /dev/fd/2 | wc -l) -eq 5")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.hourly.'   | tee /dev/fd/2 | wc -l) -eq 1")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.daily.'    | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.weekly.'   | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.monthly.'  | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.yearly.'   | tee /dev/fd/2 | wc -l) -eq 0")
          '';
        };
        # Remove snapshots
        test09.configuration = {
          npp.nas.datasets."pool0" = test01.configuration.npp.nas.datasets."pool0";
          system.build.test = ''
            server.succeed("test $(zfs get -Ho value snapdir pool0 | tee /dev/fd/2) == 'visible'")
            server.succeed("/tmp/specialisation/test09/bin/switch-to-configuration switch >&2")
            server.succeed("test $(zfs get -Ho value snapdir pool0 | tee /dev/fd/2) == 'hidden'")
            server.succeed("systemctl start npp_zfs-snapshot.service && sleep 5")
            server.wait_until_succeeds("systemctl show npp_zfs-snapshot.service | grep -qxF ActiveState=inactive", timeout=10)
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.frequent.' | tee /dev/fd/2 | wc -l) -ge 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.hourly.'   | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.daily.'    | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.weekly.'   | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.monthly.'  | tee /dev/fd/2 | wc -l) -eq 0")
            server.succeed("test $(zfs list -Ho name -t snapshot pool0 | grep -F '@npp.yearly.'   | tee /dev/fd/2 | wc -l) -eq 0")
          '';
        };

        # Make a generic config for all remaining tests
        # This is what the client will test against
        test10.configuration = {
          imports = [
            ({ nodes, ... }: {
              npp.nas = {
                datasets = {
                  "pool0" = { };
                  "pool0/dataset" = { };
                };
                nfs = with nodes.client.networking; {
                  "/mnt/pool0" = [
                    "${primaryIPAddress}/32(ro,fsid=0,all_squash)"
                  ];
                  "/mnt/pool0/dataset" = [
                    "${primaryIPAddress}/32(rw,fsid=1,all_squash)"
                  ];
                };
              };
              services.openssh = {
                enable = true;
                settings = {
                  PermitRootLogin = "yes";
                  AuthenticationMethods = "publickey";
                  PubkeyAuthentication = "yes";
                };
              };
              users.users.root.openssh.authorizedKeys.keyFiles = [ ../test.pub ];
            })
          ];
          system.build.test = ''
            server.succeed("/tmp/specialisation/test10/bin/switch-to-configuration switch >&2")
          '';
        };
      };
    };

    client = {
      imports = [
        ({ nodes, ... }: {
          boot.supportedFilesystems = [ "nfs4" "sshfs" ];
          system.fsPackages = with pkgs; [ sshfs ];
          environment.etc."test.key" = {
            # Bad security practice, but this is just a test.
            source = ../test.key;
            mode = "0600";
          };
          systemd.mounts = [
            {
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              what = "${nodes.server.networking.primaryIPAddress}:/dataset";
              where = "/mnt/nfs";
              type = "nfs4";
            }
            {
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              what = "root@${nodes.server.networking.primaryIPAddress}:/mnt/pool0/dataset";
              where = "/mnt/sshfs";
              type = "sshfs";
              options = builtins.concatStringsSep "," [
                "_netdev"
                "reconnect"
                "ServerAliveCountMax=12"
                "ServerAliveInterval=5"
                "IdentityFile=/etc/test.key"
                "StrictHostKeyChecking=no"
              ];
            }
          ];
        })
      ];
      environment.systemPackages = with pkgs; [ gawk ];
      system.build.test = ''
        client.succeed(${checkMount [ ''$1 ~ ":/dataset$"'' ''$2 == "/mnt/nfs"'' ''$3 == "nfs4"'' ]})
        client.succeed(${checkMount [ ''$1 ~ "^root@.+:/mnt/pool0/dataset$"'' ''$2 == "/mnt/sshfs"'' ''$3 == "fuse.sshfs"'' ]})
        client.succeed("touch /mnt/nfs/foo >&2")
        client.succeed("test -f /mnt/sshfs/foo >&2")
        server.succeed("test -f /mnt/pool0/dataset/foo >&2")
        client.succeed("touch /mnt/sshfs/bar >&2")
        client.succeed("test -f /mnt/nfs/bar >&2")
        server.succeed("test -f /mnt/pool0/dataset/bar >&2")
        server.succeed("touch /mnt/pool0/dataset/baz >&2")
        client.succeed("test -f /mnt/nfs/baz >&2")
        client.succeed("test -f /mnt/sshfs/baz >&2")
      '';
    };
  };

  testScript = ''
    # Set up server
    server.start()
    server.wait_for_unit("multi-user.target")
    server.succeed("ln -sf $(realpath -m /run/current-system/specialisation) /tmp/specialisation >&2")

    # Run server tests
    ${nodes.server.system.build.test}

    # Set up client
    client.start()
    client.wait_for_unit("multi-user.target")

    # Run server-client tests
    ${nodes.client.system.build.test}

    # Clean up
    client.shutdown()
    server.shutdown()
  '';

  meta.timeout = 1800; # 30m
}
