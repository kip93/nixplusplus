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
{ config, lib, pkgs, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./..};


in
{
  config = {
    systemd = {
      # Timer that will trigger the snapshots.
      timers.npp_zfs-snapshot = {
        enable = builtins.any
          ({ snapshots, ... }:
            builtins.any (x: x != null) (builtins.attrValues snapshots)
          )
          (builtins.attrValues cfg.datasets)
        ;
        description = "[ nix++ ] Automatic ZFS snapshot - timer";
        wantedBy = [ "multi-user.target" ];
        timerConfig = {
          Unit = "npp_zfs-snapshot.service";

        } // (if builtins.any ({ snapshots, ... }: snapshots.frequent or null != null) (builtins.attrValues cfg.datasets) then {
          OnCalendar = "*-*-* *:00/15";
          RandomizedDelaySec = "10m";
          AccuracySec = "1m";
          Persistent = false;

        } else if builtins.any ({ snapshots, ... }: snapshots.hourly or null != null) (builtins.attrValues cfg.datasets) then {
          OnCalendar = "*-*-* *:00";
          RandomizedDelaySec = "45m";
          AccuracySec = "5m";
          Persistent = false;

        } else if builtins.any ({ snapshots, ... }: snapshots.daily or null != null) (builtins.attrValues cfg.datasets) then {
          OnCalendar = "*-*-* 00:00";
          RandomizedDelaySec = "8h";
          AccuracySec = "1h";
          Persistent = true;

        } else if builtins.any ({ snapshots, ... }: snapshots.weekly or null != null) (builtins.attrValues cfg.datasets) then {
          OnCalendar = "Sun *-*-* 00:00";
          RandomizedDelaySec = "1d";
          AccuracySec = "1h";
          Persistent = true;

        } else if builtins.any ({ snapshots, ... }: snapshots.monthly or null != null) (builtins.attrValues cfg.datasets) then {
          OnCalendar = "*-*-01 00:00";
          RandomizedDelaySec = "7d";
          AccuracySec = "1h";
          Persistent = true;

        } else {
          OnCalendar = "*-01-01 00:00";
          RandomizedDelaySec = "7d";
          AccuracySec = "1d";
          Persistent = true;
        });
      };

      # Service that will do the actual snapshotting.
      services.npp_zfs-snapshot = with pkgs; {
        enable = true;
        description = "[ nix++ ] Automatic ZFS snapshot";
        wantedBy = [ ]; # Will be triggered by the timer above.
        path = [ findutils gnugrep config.boot.zfs.package ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart = "${writeShellScript "npp_zfs-snapshot.sh" ''
            set -eu
            timestamp="$(date -u +%Y.%m%d.%H%M%S)"

            ${builtins.concatStringsSep "" (builtins.map ({ snapshots, _id, ... }: ''
              snapshots=()
              ${lib.optionalString (snapshots.frequent or null != null) ''
                snapshots+=(${lib.escapeShellArg _id}"@npp.frequent.$timestamp")
              ''}${lib.optionalString (snapshots.hourly or null != null) ''
                zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
                |  grep -qF "@npp.hourly.''${timestamp:0:12}" \
                || snapshots+=(${lib.escapeShellArg _id}"@npp.hourly.''${timestamp:0:12}")
              ''}${lib.optionalString (snapshots.daily or null != null) ''
                zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
                |  grep -qF "@npp.daily.''${timestamp:0:9}" \
                || snapshots+=(${lib.escapeShellArg _id}"@npp.daily.''${timestamp:0:9}")
              ''}${lib.optionalString (snapshots.weekly or null != null) ''
                zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
                |  grep -qF "@npp.weekly.''${timestamp:0:5}$(date -d"$timestamp" +%V)" \
                || snapshots+=(${lib.escapeShellArg _id}"@npp.weekly.''${timestamp:0:5}$(date -d"$timestamp" +%V)")
              ''}${lib.optionalString (snapshots.monthly or null != null) ''
                zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
                |  grep -qF "@npp.monthly.''${timestamp:0:7}" \
                || snapshots+=(${lib.escapeShellArg _id}"@npp.monthly.''${timestamp:0:7}")
              ''}${lib.optionalString (snapshots.yearly or null != null) ''
                zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
                |  grep -qF "@npp.yearly.''${timestamp:0:4}" \
                || snapshots+=(${lib.escapeShellArg _id}"@npp.yearly.''${timestamp:0:4}")
              ''}
              for snapshot in "''${snapshots[@]}"; do
                zfs snapshot -r "$snapshot"
              done

              zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
              | grep -F '@npp.frequent.' \
              | head -n -${toString (
                if snapshots.frequent or null != null then
                  snapshots.frequent
                else
                  0
              )} | xargs -rn1 zfs destroy -r
              zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
              | grep -F '@npp.hourly.' \
              | head -n -${toString (
                if snapshots.hourly or null != null then
                  snapshots.hourly
                else
                  0
              )} | xargs -rn1 zfs destroy -r
              zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
              | grep -F '@npp.daily.' \
              | head -n -${toString (
                if snapshots.daily or null != null then
                  snapshots.daily
                else
                  0
              )} | xargs -rn1 zfs destroy -r
              zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
              | grep -F '@npp.weekly.' \
              | head -n -${toString (
                if snapshots.weekly or null != null then
                  snapshots.weekly
                else
                  0
              )} | xargs -rn1 zfs destroy -r
              zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
              | grep -F '@npp.monthly.' \
              | head -n -${toString (
                if snapshots.monthly or null != null then
                  snapshots.monthly
                else
                  0
              )} | xargs -rn1 zfs destroy -r
              zfs list -Ho name -t snapshot ${lib.escapeShellArg _id} \
              | grep -F '@npp.yearly.' \
              | head -n -${toString (
                if snapshots.yearly or null != null then
                  snapshots.yearly
                else
                  0
              )} | xargs -rn1 zfs destroy -r
            '') (builtins.attrValues cfg.datasets))}
          ''}";
        };
      };
    };
  };
}
