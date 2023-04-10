{ self, ... } @ inputs:
{ config, lib, pkgs, ... }:
let
  cfg = config.nixplusplus.${builtins.baseNameOf ./.};

in
{
  options.nixplusplus.${builtins.baseNameOf ./.} = with lib; {
    schedule = mkOption {
      type = types.nonEmptyStr;
      description = mdDoc ''
        A schedule defining calendar events when clean ups should be done, in [a format
        supported by systemd][systemd.time(7)].

        You can use [systemd-analyze calendar '<SCHEDULE>'][systemd.analyze(1)] to test
        out expressions.

        [systemd.analyze(1)]: https://www.freedesktop.org/software/systemd/man/systemd-analyze.html
        [systemd.time(7)]: https://www.freedesktop.org/software/systemd/man/systemd.time.html
      '';
    };
    last = mkOption {
      type = types.ints.unsigned;
      description = mdDoc ''
        Keep the last N generations, excluding the current one.
      '';
      default = 5;
    };
    days = mkOption {
      type = types.ints.unsigned;
      description = mdDoc ''
        Keep generations newer than N days, excluding the current one.
      '';
      default = 28;
    };
  };

  config = {
    systemd = {
      # Timer that will trigger the clean up.
      timers.nixplusplus_nix-gc = {
        enable = true;
        description = "[ nix++ ] Automatic Nix GC - timer";
        wantedBy = [ "multi-user.target" ];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Unit = "nixplusplus_nix-gc.service";
        };
      };

      # Service that will do the actual clean up.
      services.nixplusplus_nix-gc = {
        enable = true;
        description = "[ nix++ ] Automatic Nix GC";
        wantedBy = [ ]; # Will be triggered by the timer above.
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart =
            with self.packages.${pkgs.buildPlatform.system}.${pkgs.targetPlatform.system};
            "${nix-gc}/bin/nix-gc -l${toString cfg.last} -d${toString cfg.days}"
          ;
        };
      };
    };
  };

  meta.doc = ./README.md;
}
