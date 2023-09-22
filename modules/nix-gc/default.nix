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

{ self, ... } @ inputs:
{ config, lib, pkgs, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./.};

in
{
  options.npp.${builtins.baseNameOf ./.} = with lib; {
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
      default = "0:0";
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
    nix.gc.automatic = self.lib.mkForce false;

    systemd = {
      # Timer that will trigger the clean up.
      timers.npp_nix-gc = {
        enable = true;
        description = "[ nix++ ] Automatic Nix GC - timer";
        wantedBy = [ "multi-user.target" ];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Unit = "npp_nix-gc.service";
        };
      };

      # Service that will do the actual clean up.
      services.npp_nix-gc = {
        enable = true;
        description = "[ nix++ ] Automatic Nix GC";
        wantedBy = [ ]; # Will be triggered by the timer above.
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart =
            with self.packages.${pkgs.buildPlatform.system}.${pkgs.hostPlatform.system};
            "${nix-gc}/bin/nix-gc -l${toString cfg.last} -d${toString cfg.days}"
          ;
        };
      };
    };
  };
}
