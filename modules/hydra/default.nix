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

{ nixos-artwork, self, ... } @ inputs:
{ lib, ... }:
let
  nonGlobStr = with lib.types; mkOptionType {
    name = "nonGlobStr";
    description = "(optionally newline-terminated) non-glob single-line string";
    descriptionClass = "noun";
    check = x: singleLineStr.check x && builtins.match "\\*" x == null;
    inherit (singleLineStr) merge;
  };

in
{
  imports = self.lib.import.asList' {
    path = ./.;
    apply = _: module: module inputs;
  };

  options.npp.${builtins.baseNameOf ./.} = with lib; {
    url = mkOption {
      type = types.singleLineStr;
      description = mdDoc ''
        The public facing URL of the hydra server.
      '';
      example = "hydra.example.com";
    };
    useACME = mkOption {
      type = types.bool;
      description = mdDoc ''
        If Let's encrypt should be used instead of generating a self-signed certificate.
      '';
      default = true;
    };
    email = mkOption {
      type = types.nullOr types.singleLineStr;
      description = mdDoc ''
        Email used to create the SSL certificate.
      '';
      default = null;
      defaultText = literalMD ''
        if `useACME` is `true`, `null` means that `config.security.acme.defaults.email`
        will be used. If `useACME` is `false`, then a `null` value will omit the email
        field in the self-signed cert.
      '';
      example = "hydra@example.com";
    };

    passwordFile = mkOption {
      type = types.path;
      description = mdDoc ''
        File containing the encrypted password for the admin user.

        NOTE: The password needs to be hashed using argon2, and <=127 chars long.

        ```sh
        $ tr -d \\n | nix run nixpkgs#libargon2 -- \
          "$(LC_ALL=C tr -dc '[:alnum:]' </dev/urandom | head -c16)" \
          -id -t 3 -k 262144 -p 1 -l 16 -e
        foobar
        ^D
        $argon2id$v=19$m=262144,t=3,p=1$NFU1QXJRNnc4V1BhQ0NJQg$6GHqjqv5cNDDwZqrqUD0zQ
        ```
      '';
    };

    logo = mkOption {
      type = types.nullOr types.path;
      description = mdDoc ''
        Logo to be show on the top left corner.
      '';
      default = "${nixos-artwork}/logo/nix-snowflake.svg";
      defaultText = literalExpression ''"''${nixos-artwork}/logo/nix-snowflake.svg"'';
      example = "/var/hydra/logo.png";
    };

    commands = mkOption {
      type = types.listOf
        (types.submodule {
          options = {
            project = mkOption {
              type = types.nullOr nonGlobStr;
              description = mdDoc ''
                The name of the project. Defaults to all projects.
              '';
              default = null;
            };
            jobset = mkOption {
              type = types.nullOr nonGlobStr;
              description = mdDoc ''
                The name of the jobset. Defaults to all jobsets.
              '';
              default = null;
            };
            job = mkOption {
              type = types.nullOr nonGlobStr;
              description = mdDoc ''
                The name of the job. Defaults to all jobs.
              '';
              default = null;
            };
            command = mkOption {
              type = types.nonEmptyStr;
              description = mdDoc ''
                Command to run. Can use the `$HYDRA_JSON` environment variable to access
                information about the build.

                Explained contents of `$HYDRA_JSON`:
                ```jsonc
                ${builtins.readFile ./schema.jsonc}
                ```
              '';
            };
          };
        })
      ;
      description = mdDoc ''
        Configure specific commands to execute after the specified matching jobs
        finish.
      '';
      default = [ ];
      example = [{
        project = "example-project";
        command = "cat $HYDRA_JSON >/tmp/hydra-output";
      }];
    };

    extraConfig = mkOption {
      type = types.lines;
      description = mdDoc ''
        Additional hydra configuration entries.
      '';
      default = "";
      example = ''
        evaluator_workers = 1
      '';
    };
  };
}
