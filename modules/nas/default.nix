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
{ config, lib, utils, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./.};
  config' = config; # Avoid obscuring this.

in
{
  imports = self.lib.import.asList' {
    path = ./.;
    apply = _: module: module inputs;
  };

  options.npp.${builtins.baseNameOf ./.} = with lib; {
    datasets = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          mountPoint = mkOption {
            type = types.nullOr types.path;
            description = mdDoc ''
              Where to mount the dataset. Null makes it inherit from parent dataset. Pools
              can't have null mountpoints, so they default to `/mnt/<POOL_NAME>`.
            '';
            default = null;
          };
          properties = mkOption {
            type = (types.attrsOf types.singleLineStr) // {
              check = x: isAttrs x && !(x ? mountpoint);
            };
            description = mdDoc ''
              Properties of this zfs dataset.
            '';
            default = { };
          };

          snapshots = mkOption {
            type = types.submodule {
              options = {
                frequent = mkOption {
                  type = types.nullOr types.ints.positive;
                  description = mdDoc ''
                    Keep one snapshot for each 15 minutes from the last N quarter hour(s).
                  '';
                  default = null;
                };
                hourly = mkOption {
                  type = types.nullOr types.ints.positive;
                  description = mdDoc ''
                    Keep one snapshot for each hour from the last N hour(s).
                  '';
                  default = null;
                };
                daily = mkOption {
                  type = types.nullOr types.ints.positive;
                  description = mdDoc ''
                    Keep one snapshot for each day from the last N day(s).
                  '';
                  default = null;
                };
                weekly = mkOption {
                  type = types.nullOr types.ints.positive;
                  description = mdDoc ''
                    Keep one snapshot for each week from the last N week(s).
                  '';
                  default = null;
                };
                monthly = mkOption {
                  type = types.nullOr types.ints.positive;
                  description = mdDoc ''
                    Keep one snapshot for each month from the last N month(s).
                  '';
                  default = null;
                };
                yearly = mkOption {
                  type = types.nullOr types.ints.positive;
                  description = mdDoc ''
                    Keep one snapshot for each year from the last N year(s).
                  '';
                  default = null;
                };
              };
            };
            description = mdDoc ''
              Specifies which snapshots should be kept after clean up.

              Should not affect snapshots manually created.
            '';
            default = { };
            example = { daily = 7; weekly = 4; };
          };

          _id = mkOption {
            type = types.singleLineStr;
            description = mdDoc ''
              The zfs dataset's name.
            '';
            readOnly = true;
            visible = false;
          };
          _pool = mkOption {
            type = types.singleLineStr;
            description = mdDoc ''
              The pool containing this dataset.
            '';
            readOnly = true;
            visible = false;
          };
          _mountPoint = mkOption {
            type = types.singleLineStr;
            description = mdDoc ''
              Computed mountpoint.
            '';
            readOnly = true;
            visible = false;
          };
          _properties = mkOption {
            type = types.attrsOf types.singleLineStr;
            description = mdDoc ''
              Computed properties.
            '';
            readOnly = true;
            visible = false;
          };

          _isPool = mkOption {
            type = types.bool;
            description = mdDoc ''
              Whether this is a zfs pool.
            '';
            readOnly = true;
            visible = false;
          };
          _neededForBoot = mkOption {
            type = types.bool;
            description = mdDoc ''
              Whether this dataset is mounted in initrd.
            '';
            readOnly = true;
            visible = false;
          };
        };

        config = {
          _id = name;
          _pool =
            if config._isPool then
              name
            else
              cfg.datasets.${builtins.dirOf name}._pool
          ;
          _mountPoint =
            if config.mountPoint != null then
              lib.removeSuffix "/" config.mountPoint

            else if config._isPool then
              "/mnt/${name}"

            else
              "${
                cfg.datasets.${builtins.dirOf name}._mountPoint
              }/${
                builtins.baseNameOf name
              }"
          ;
          _properties = config.properties // {
            mountpoint = "legacy";
          } // (lib.optionalAttrs
            (builtins.any (x: x != null)
              (builtins.attrValues config.snapshots)
            )
            { snapdir = "visible"; }
          );

          _isPool = !lib.hasInfix "/" name;
          _neededForBoot =
            (builtins.any
              (path:
                let
                  normalize = x:
                    "${x}${lib.optionalString (!lib.hasSuffix "/" x) "/"}"
                  ;

                in
                lib.hasPrefix (normalize config._mountPoint) (normalize path)
              )
              utils.pathsNeededForBoot
            ) || (
              config'.fileSystems."npp_zfs_${name}".neededForBoot or false
            )
          ;
        };
      }));
      description = mdDoc ''
        Configure zfs pools, datasets, and their properties. If datasets don't exist,
        they will be created. This module won't create pools on its own though, just
        manage them. If a pool or dataset is found that is not declared here, a warning
        will be raised but it won't cause failures for the most part, except for boot
        critical problems.

        Adding, removing, and modifying datasets on the fly is supported, but any zfs
        dataset mounts "needed for boot" this module of course won't be able to remove.
        For changing these datasets you'll need to restart the machine.

        NOTE: Don't set the mountpoint property directly, since this will be ignored and
        set to "legacy". Instead, use the mountPoint option.
      '';
      default = { };
      example = {
        "rpool" = {
          mountPoint = "/";
          properties = {
            atime = "off";
            relatime = "off";
            exec = "off";
            compress = "lz4";
            checksum = "on";
          };
        };
        "rpool/nix" = {
          properties.exec = "on";
        };
        "rpool/data" = {
          mountPoint = "/mnt/data";
          snapshots = { hours = 24; days = 7; weeks = 52; };
        };
        "rpool/configs" = { };
      };
    };

    nfs = mkOption {
      type = (types.attrsOf (types.listOf types.singleLineStr)) // {
        check = x: isAttrs x && (builtins.all
          (key: types.path.check key)
          (builtins.attrNames x)
        );
      };
      description = mdDoc ''
        Set the entries for the NFSv4 server export table. Check the
        [man page][exports(5)] for details on the format.

        [exports(5)]: https://linux.die.net/man/5/exports
      '';
      default = { };
      example = {
        "/mnt/pool0/foo" = [
          "192.168.1.0/24(rw,insecure,subtree_check)"
          "*(ro,insecure,subtree_check,all_squash)"
        ];
        "/mnt/pool0/bar" = [
          "*(rw,subtree_check,all_squash,sec=krb5p)"
        ];
      };
    };
  };
}
