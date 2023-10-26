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
{ config, options, pkgs, ... }:
let
  cfg = config.npp.${builtins.baseNameOf ./..};
  port = (import ../../ports.nix).hydra;

in
{
  config = {
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

    npp.secrets."npp.hydra.password" = {
      file = cfg.passwordFile;
      mode = "440";
      owner = "hydra";
      group = "hydra";
    };

    services.hydra = {
      enable = true;
      listenHost = "127.0.0.1";
      inherit port;
      hydraURL = cfg.url;
      notificationSender = "noone@nowhere";
      useSubstitutes = true;
      inherit (cfg) logo;
      extraConfig = ''
        # Increase timeout for big repos like nixpkgs
        <git-input>
          timeout = 3600
        </git-input>

        # This is a risk, best disable it
        <dynamicruncommand>
          enable = 0
        </dynamicruncommand>

        # Run these commands after a job finishes (if they match the given pattern)
        ${builtins.concatStringsSep "" (builtins.map (cmd: ''
          <runcommand>
            job = ${
              if cmd.project == null then
                "*"
              else
                cmd.project
            }:${
              if cmd.jobset == null then
                "*"
              else
                cmd.jobset
            }:${
              if cmd.job == null then
                "*"
              else
                cmd.job
            }
            command = ${cmd.command}
          </runcommand>
        '') cfg.commands)}

        ${cfg.extraConfig}
      '';
    };

    # Create admin user "declaratively" (hydra#958)
    systemd.services.npp_configure-hydra-user = {
      inherit (config.services.hydra) enable;
      wantedBy = [ "multi-user.target" ];
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" "hydra-init.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "hydra";
        ExecStart = "${pkgs.writeShellScript "npp_configure-hydra-user.sh" ''
          ${config.services.hydra.package}/bin/hydra-create-user admin \
            --role admin \
            --password-hash "$(<${config.npp.secrets."npp.hydra.password".path})"
        ''}";
      };
    };
  };
}
