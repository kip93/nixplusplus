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
{ config, lib, options, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./.};
  cfg_secrets = config.npp.secrets;

in
{
  options.npp.${builtins.baseNameOf ./.} = with lib; {
    user = mkOption {
      type = types.singleLineStr;
      description = mdDoc ''
        Name of the user to execute the backups. Needs to have permission to access the
        files to be backed up.
      '';
      default = "root";
    };

    passwordFile = mkOption {
      type = types.path;
      description = mdDoc ''
        File containing the encrypted password, to be used to the encrypt the backups
        before transit.

        NOTE: The password needs to be SHA256 hashed.

        ```sh
        $ openssl passwd -6
        Password:
        Verifying - Password:
        $6$VuJ9jTKK5jOdG8s4$L76ZuXThBEW4QQ2VZi6M9lPrvkCqLVxxHmUx.2zaecce0OOxmbSRqzefoSeO7TZe60a2QL6il8uXmRPndjojg1
        ```
      '';
    };
    sshConfig = mkOption {
      type = types.path;
      description = mdDoc ''
        An SSH configuration file, which must contain a host entry for `backup-server`,
        which specifies how to connect to the backup server. Must be encrypted.
      '';
    };
    sshKey = mkOption {
      type = types.path;
      description = mdDoc ''
        The encrypted SSH private key, to be used to connect to the backup server.
      '';
    };

    paths = mkOption {
      type = types.listOf
        (types.submodule {
          options = {
            srcs = mkOption {
              type = types.listOf types.nonEmptyStr;
              description = mdDoc ''
                A list of local paths to be backed up.
              '';
            };
            dst = mkOption {
              type = types.nonEmptyStr;
              description = mdDoc ''
                A path to the target folder on the backup server where files will be backed up
                to.
              '';
            };
          };
        });
      description = mdDoc ''
        A list of backups to be done, in the form `srcs` -> `dst`, where `srcs` is a
        list of local paths to be backed up, and `dst` is the target folder in the
        backup server.
      '';
      example = [{
        srcs = [ "/var/important_data" ];
        dst = ".local/share/backups/important_data";
      }];
    };

    schedule = mkOption {
      type = types.nonEmptyStr;
      description = mdDoc ''
        A schedule defining calendar events when backups should be done, in [a format
        supported by systemd][systemd.time(7)].

        You can use [systemd-analyze calendar '<SCHEDULE>'][systemd.analyze(1)] to test
        out expressions.

        [systemd.analyze(1)]: https://www.freedesktop.org/software/systemd/man/systemd-analyze.html
        [systemd.time(7)]: https://www.freedesktop.org/software/systemd/man/systemd.time.html
      '';
    };

    keep = mkOption {
      type = types.submodule {
        options = {
          last = mkOption {
            type = types.nullOr types.ints.positive;
            description = mdDoc ''
              Keep the last N backup(s) made.
            '';
            default = null;
          };
          hours = mkOption {
            type = types.nullOr types.ints.positive;
            description = mdDoc ''
              Keep one backup for each hour from the last N hour(s).
            '';
            default = null;
          };
          days = mkOption {
            type = types.nullOr types.ints.positive;
            description = mdDoc ''
              Keep one backup for each day from the last N day(s).
            '';
            default = null;
          };
          weeks = mkOption {
            type = types.nullOr types.ints.positive;
            description = mdDoc ''
              Keep one backup for each week from the last N week(s).
            '';
            default = null;
          };
          months = mkOption {
            type = types.nullOr types.ints.positive;
            description = mdDoc ''
              Keep one backup for each month from the last N month(s).
            '';
            default = null;
          };
          years = mkOption {
            type = types.nullOr types.ints.positive;
            description = mdDoc ''
              Keep one backup for each year from the last N year(s).
            '';
            default = null;
          };
        };
      };
      description = mdDoc ''
        Specifies which backups should be kept after clean up.
      '';
      example = { last = 5; days = 7; weeks = 4; };
    };
  };

  config = {
    warnings = (
      # Suggest sane "keep" settings.
      lib.optional (builtins.all (x: x == null) (builtins.attrValues cfg.keep)) ''
        You should set at least one of the "keep" options, otherwise only a single
        backup will be kept at any given time, reducing their usefulness in case of
        catastrophic failure.

        Check the example for a good starting point.
      ''
    ) ++ (
      # Check there's stuff to backup.
      lib.optional (builtins.length cfg.paths == 0) ''
        You're not backing up any paths. You need to set the "paths" option to at least
        one source and destination, otherwise nothing will be done.
      ''
    ) ++ (
      # Check there's no empty backups.
      lib.optional (builtins.any (x: builtins.length x.srcs == 0) cfg.paths) ''
        There's empty backups. Check that there's at least one source for every backup
        destination, otherwise you may be missing backups of important data.
      ''
    );
    assertions = [
      {
        # Check on requirements.
        assertion = options.npp ? secrets;
        message = ''
          `npp.nixosModules.secrets` module not installed, which is needed for decrypting
          secrets.
        '';
      }
    ];

    npp.secrets = {
      "npp.backup.password" = { file = cfg.passwordFile; owner = cfg.user; };
      "npp.backup.sshconfig" = { file = cfg.sshConfig; owner = cfg.user; };
      "npp.backup.sshkey" = { file = cfg.sshKey; owner = cfg.user; };
    };

    services.restic.backups =
      builtins.listToAttrs (builtins.map
        (p: {
          name = lib.strings.sanitizeDerivationName p.dst;
          value = {
            initialize = true;
            inherit (cfg) user;
            repository = "sftp:backup-server:${p.dst}";
            paths = p.srcs;
            passwordFile = cfg_secrets."npp.backup.password".path;
            extraOptions = [
              (
                "sftp.command='ssh " +
                ''-o StrictHostKeyChecking=accept-new '' +
                ''-o ServerAliveInterval=60 '' +
                ''-o ServerAliveCountMax=240 '' +
                ''-F '"'"'${cfg_secrets."npp.backup.sshconfig".path}'"'"' '' +
                ''backup-server '' +
                ''-i '"'"'${cfg_secrets."npp.backup.sshkey".path}'"'"' '' +
                "-s sftp'"
              )
            ];

            timerConfig = { OnCalendar = cfg.schedule; };
            pruneOpts =
              (lib.optional (cfg.keep.last != null) "--keep-last ${toString cfg.keep.last}") ++
              (lib.optional (cfg.keep.hours != null) "--keep-hourly ${toString cfg.keep.hours}") ++
              (lib.optional (cfg.keep.days != null) "--keep-daily ${toString cfg.keep.days}") ++
              (lib.optional (cfg.keep.weeks != null) "--keep-weekly ${toString cfg.keep.weeks}") ++
              (lib.optional (cfg.keep.months != null) "--keep-monthly ${toString cfg.keep.months}") ++
              (lib.optional (cfg.keep.years != null) "--keep-yearly ${toString cfg.keep.years}");
          };
        })
        cfg.paths
      );
  };
}
