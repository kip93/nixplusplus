{ ... } @ inputs:
{ config, lib, options, ... }:
let
  cfg = config.nixplusplus.backup;
in
{
  options.nixplusplus.backup = with lib; {
    user = mkOption { type = types.singleLineStr; default = "root"; };
    passwordFile = mkOption { type = types.path; };
    sshConfig = mkOption { type = types.path; };
    sshKey = mkOption { type = types.path; };

    paths = mkOption {
      type = types.listOf
        (types.submodule {
          options = {
            srcs = mkOption { type = types.listOf types.nonEmptyStr; };
            dst = mkOption { type = types.nonEmptyStr; };
          };
        });
    };

    schedule = mkOption { type = types.nonEmptyStr; };

    keep = {
      last = mkOption { type = types.nullOr types.ints.positive; default = null; };
      hours = mkOption { type = types.nullOr types.ints.positive; default = null; };
      days = mkOption { type = types.nullOr types.ints.positive; default = null; };
      weeks = mkOption { type = types.nullOr types.ints.positive; default = null; };
      months = mkOption { type = types.nullOr types.ints.positive; default = null; };
      years = mkOption { type = types.nullOr types.ints.positive; default = null; };
    };
  };

  config = {
    assertions = [{ assertion = (options ? age); message = "Agenix module not installed"; }];

    age.secrets =
      let
        permissions = { mode = "600"; owner = cfg.user; };
      in
      {
        "backup.password" = { file = cfg.passwordFile; } // permissions;
        "backup.sshconfig" = { file = cfg.sshConfig; } // permissions;
        "backup.sshkey" = { file = cfg.sshKey; } // permissions;
      };

    services.restic.backups =
      builtins.listToAttrs (builtins.map
        (p: {
          name = lib.strings.sanitizeDerivationName p.dst;
          value = {
            initialize = true;
            user = cfg.user;
            repository = "sftp:backup-server:${p.dst}";
            paths = p.srcs;
            passwordFile = config.age.secrets."backup.password".path;
            extraOptions = [
              (
                "sftp.command='ssh " +
                ''-o StrictHostKeyChecking=accept-new '' +
                ''-o ServerAliveInterval=60 '' +
                ''-o ServerAliveCountMax=240 '' +
                ''-F '"'"'${config.age.secrets."backup.sshconfig".path}'"'"' '' +
                ''backup-server '' +
                ''-i '"'"'${config.age.secrets."backup.sshkey".path}'"'"' '' +
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
