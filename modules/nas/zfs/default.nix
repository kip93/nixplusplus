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

{ self, ... } @ _inputs:
{ config, lib, pkgs, utils, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./..};

  inherit (utils) escapeSystemdPath;

  # These scripts do not include any explicit binaries to avoid bloating initrd.
  # Instead, they assume POSIX tools are available (i.e., busybox)

  setProperties = with pkgs; writeScript "npp_zfs-set-properties.sh" ''
    #!/bin/sh
    set -eu

    name="$(jq -rn --argjson x "$1" '$x.name')"
    for property in $(jq -rn \
      --argjson x "$1" \
      '$x.properties|($ARGS.positional-keys)[]' \
      --args $(zfs get -Ho property,source all "$name" | awk '$2~/^local$/{print $1}') \
    ) ; do
      zfs inherit "$property" "$name"
    done

    for property in $(jq -rn \
      --argjson x "$1" \
      '$x.properties|to_entries|map(.key+"="+.value)[]' \
    ) ; do
      zfs set "$property" "$name"
    done
  '';

  handlePools = pools: ''
    for pool in ${lib.escapeShellArgs
      (builtins.map ({ _id, ... }: _id) pools)
    } ; do
      zpool list "$pool" >/dev/null 2>&1 \
      || MISSING_POOLS="''${MISSING_POOLS:-}''${MISSING_POOLS:+ }$pool"
    done

    [ -z "''${MISSING_POOLS:-}" ] || {
      printf '\x1B[31mMissing pools:\x1B[0m\n' ;
      printf '\x1B[31m * %s\x1B[0m\n' $MISSING_POOLS ;
      printf '\x1B[31m%s\x1B[0m\n' ${lib.escapeShellArgs (lib.splitString "\n" ''
        You need to create the pools manually. e.g.,
        ```sh
        $ zpool create foobar mirror /dev/sd[a-b]
        ```
      '')}
      fail ;
    }

    ${builtins.concatStringsSep "" (builtins.map ({ _id, _properties, ... }: ''
      ${setProperties} ${lib.escapeShellArg (builtins.toJSON {
        name = _id;
        properties = _properties;
      })}
    '') pools)}
  '';

  handleDatasets = datasets: ''
    for dataset in ${lib.escapeShellArgs
      (builtins.map ({ _id, ... }: _id) datasets)
    } ; do
      zfs list "$dataset" >/dev/null 2>&1 \
      || (
        printf 'Creating dataset %s...\n' "$dataset" \
        && zfs create "$dataset"
      )
    done

    ${builtins.concatStringsSep "" (builtins.map ({ _id, _properties, ... }: ''
      ${setProperties} ${lib.escapeShellArg (builtins.toJSON {
        name = _id;
        properties = _properties;
      })}
    '') datasets)}
  '';

in
{
  config = {
    networking.hostId = self.lib.mkDefault "00000000";
    boot = {
      kernelPackages =
        config.boot.zfs.package.latestCompatibleLinuxPackages
      ;
      initrd = {
        supportedFilesystems = [ "zfs" ];
        extraUtilsCommands = "copy_bin_and_libs ${pkgs.jq}/bin/jq";
        postDeviceCommands =
          let
            pools = lib.unique (builtins.map
              ({ _pool, ... }: cfg.datasets.${_pool})
              (builtins.filter
                ({ _neededForBoot, ... }: _neededForBoot)
                (builtins.attrValues cfg.datasets)
              )
            );
            datasets = builtins.filter
              ({ _isPool, _neededForBoot, ... }: _neededForBoot && !_isPool)
              (builtins.attrValues cfg.datasets)
            ;

          in
          lib.mkAfter (lib.optionalString (builtins.length pools > 0) ''
            printf '[ nix++ ] Setting up ZFS...\n'
            ${handlePools pools}
            ${lib.optionalString (builtins.length datasets > 0) ''
              ${handleDatasets datasets}
            ''}
            printf '[ nix++ ] ZFS setup finished.\n'
          '')
        ;
      };
      supportedFilesystems = [ "zfs" ];
      zfs = { forceImportRoot = false; allowHibernation = false; };
    };
    virtualisation = {
      docker.storageDriver = self.lib.mkDefault "zfs";
      cri-o.storageDriver = self.lib.mkDefault "zfs";
    };
    systemd.services = with pkgs; {
      docker.path = [ config.boot.zfs.package ];
      crio.path = [ config.boot.zfs.package ];
      npp_zfs-config = {
        enable = true;
        description = "[ nix++ ] ZFS configure";
        wantedBy = [ "sysinit.target" "local-fs.target" ];
        wants = [ "zfs-import.target" ];
        after = [ "zfs-import.target" ];
        before = [ "local-fs.target" ] ++ builtins.map
          ({ _mountPoint, ... }: "${escapeSystemdPath _mountPoint}.mount")
          (builtins.attrValues cfg.datasets)
        ;
        path = [ busybox jq config.boot.zfs.package ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart =
            let
              pools = lib.unique (builtins.map
                ({ _pool, ... }: cfg.datasets.${_pool})
                (builtins.filter
                  ({ _neededForBoot, ... }: !_neededForBoot)
                  (builtins.attrValues cfg.datasets)
                )
              );
              datasets = builtins.filter
                ({ _isPool, _neededForBoot, ... }: !_neededForBoot && !_isPool)
                (builtins.attrValues cfg.datasets)
              ;

            in
            "${writeShellScript "npp_zfs-config.sh" ''
              set -eu -o pipefail

              fail() { exit 1; }
              ${lib.optionalString (builtins.length pools > 0) ''
                ${handlePools pools}
                ${lib.optionalString (builtins.length datasets > 0) ''
                  ${handleDatasets datasets}
                ''}
              ''}

              DATASETS="$(zfs list -Ho name)"
              [ ${lib.escapeShellArg (builtins.length (builtins.attrValues cfg.datasets))} -eq 0 ] \
              && UNMANAGED_DATASETS="$DATASETS" \
              || UNMANAGED_DATASETS="$(
                printf '%s\n' $DATASETS \
                | grep -vxF $(printf -- '-e %s ' ${lib.escapeShellArgs
                  (builtins.map ({ _id, ... }: _id) (builtins.attrValues cfg.datasets))
                }) ||:
              )"

              [ -z "$UNMANAGED_DATASETS" ] || (
                printf '\x1B[33mUnmanaged datasets found:\x1B[0m\n'
                printf '\x1B[33m * %s\x1B[0m\n' $UNMANAGED_DATASETS
                printf '\x1B[33m%s\x1B[0m\n' ${lib.escapeShellArgs (lib.splitString "\n" ''
                  To fix this issue, follow one of these solutions:
                  * Adopt them by adding them to the NixOS configuration:
                    ```nix
                    { config.npp.nas.datasets."foo/bar" = { }; }
                    ```
                  * If they are not needed anymore, they can be deleted by running:
                    ```sh
                    # Check what would be deleted first
                    $ zfs destroy -nv foo/bar@%
                    # Unmount and destroy the dataset
                    $ zfs destroy -f foo/bar@%
                    # If the dataset has children that you also want to delete, use this instead
                    $ zfs destroy -rf foo/bar@%
                    # If it is a pool
                    $ zpool destroy -f foo@%
                    ```
                '')}
              )
            ''}"
          ;
        };
        restartIfChanged = true;
        # This service is part of system init, so this setting saves us from a
        # dependency cycle
        unitConfig.DefaultDependencies = false;
      };
    };
    services.zfs.autoScrub = {
      enable = true;
      pools = [ ]; # All pools
    };

    # TODO Find a way to properly set filesystems in the test suite (I'd use
    #      `virtualisation.fileSystems = lib.mkForce { };`, IF IT WORKED!
    #      Somehow, somewhere, a mkVMOverride is making this impossible)
    fileSystems = (if cfg._test or false then self.lib.mkStrict else lib.mkIf true)
      (builtins.listToAttrs (builtins.map
        ({ _id, _mountPoint, ... }: {
          name = "npp_zfs_${_id}";
          value = {
            device = _id;
            fsType = "zfs";
            mountPoint = _mountPoint;
          };
        })
        (builtins.attrValues cfg.datasets)
      ))
    ;
  };
}
