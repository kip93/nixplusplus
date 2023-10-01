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
pkgs.nixosTest {
  name = builtins.baseNameOf ./.;

  nodes = {
    client = {
      imports = with self.nixosModules; [ secrets backup ];
      virtualisation.graphics = false;

      # Bad security practice, but this is just a test.
      npp.secrets_key = "${../test.key}";
      npp.backup = {
        passwordFile = ./backup.password.age;
        sshConfig = ./backup.sshconfig.age;
        sshKey = ./backup.sshkey.age;

        paths = [{ srcs = [ "/var/data" ]; dst = "backups/test_backup/"; }];
        schedule = "*:*:0/30";

        keep = { last = 5; days = 7; weeks = 4; };
      };
    };

    server = { pkgs, ... }: {
      virtualisation.graphics = false;
      virtualisation.writableStore = true;

      environment.systemPackages = with pkgs; [ restic rage ];

      services.openssh.enable = true;

      users.users.backup = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAq7DAZ9i/+9eBSWW95LCUATBuSRbRgZt14gmnA754dQ"
        ];
      };
    };
  };

  testScript = ''
    client.start()
    client.copy_from_host("${./data}", "/var/data")
    client.shutdown()

    server.start()
    server.wait_for_open_port(22)

    client.start()
    client.wait_for_console_text("Started restic-backups-backups-test_backup-\.timer\.")
    client.wait_for_console_text("Starting restic-backups-backups-test_backup-\.service\.\.\.")
    client.wait_for_console_text("Applying Policy: keep 5 latest, 7 daily, 4 weekly snapshots")
    client.wait_for_console_text("check snapshots, trees and blobs")
    client.wait_for_console_text("no errors were found")
    client.wait_for_console_text("Finished restic-backups-backups-test_backup-\.service\.")
    client.shutdown()

    server.copy_from_host("${../test.key}", "/tmp/agenix.key")
    server.copy_from_host("${./backup.password.age}", "/tmp/password.age")
    server.succeed("rage --decrypt -i /tmp/agenix.key -o /tmp/password /tmp/password.age")
    server.succeed("restic -p /tmp/password -r /home/backup/backups/test_backup dump latest /var/data/test_data.txt | grep -qz '^Hello, world!\n$'")
    server.succeed("restic -p /tmp/password -r /home/backup/backups/test_backup restore latest -t /tmp/restored")
    server.succeed("grep -qz '^Hello, world!\n$' /tmp/restored/var/data/test_data.txt")
    server.shutdown()
  '';

  meta.timeout = 180;
}
