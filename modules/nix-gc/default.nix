{ self, ... } @ inputs:
{ config, lib, pkgs, ... }:
let
  cfg = config.nixplusplus.nix-gc;

in
{
  options.nixplusplus.nix-gc = with lib; {
    schedule = mkOption { type = types.nonEmptyStr; };
    last = mkOption { type = types.ints.unsigned; default = 5; };
    days = mkOption { type = types.ints.unsigned; default = 28; };
  };

  config = {
    systemd = {
      timers.nixplusplus_nix-gc = {
        enable = true;
        description = "[ nix++ ] Automatic Nix GC - timer";
        wantedBy = [ "multi-user.target" ];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Unit = "nixplusplus_nix-gc.service";
        };
      };

      services.nixplusplus_nix-gc = {
        enable = true;
        description = "[ nix++ ] Automatic Nix GC";
        wantedBy = [ ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart =
            with self.packages.${pkgs.system};
            "${nix-gc}/bin/nix-gc -l${toString cfg.last} -d${toString cfg.days}";
        };
      };
    };
  };
}
