{ nixpkgs, self, system, ... } @ args:
nixpkgs.legacyPackages.${system}.nixosTest {
  name = "backup_module";

  nodes = {
    client = {
      imports = with self.nixosModules; [ agenix backup ];
      virtualisation.graphics = false;

      age.identityPaths = [ "/etc/nixos/agenix.key" ];
      nixplusplus.backup = {
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
    client.copy_from_host("${../test.key}", "/etc/nixos/agenix.key")
    client.copy_from_host("${./data}", "/var/data")
    client.shutdown()

    server.start()
    server.wait_for_open_port(22)

    client.start()
    client.wait_for_console_text("Started restic-backups-backups-test_backup-.timer.")
    client.wait_for_console_text("Starting restic-backups-backups-test_backup-.service...")
    client.wait_for_console_text("Applying Policy: keep 5 latest, 7 daily, 4 weekly snapshots")
    client.wait_for_console_text("check snapshots, trees and blobs")
    client.wait_for_console_text("no errors were found")
    client.wait_for_console_text("Finished restic-backups-backups-test_backup-.service.")
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
