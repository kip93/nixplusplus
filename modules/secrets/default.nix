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

{ agenix, ... } @ inputs:
{ config, lib, ... }:
let
  secrets = config.nixplusplus.${builtins.baseNameOf ./.};
  key = config.nixplusplus."${builtins.baseNameOf ./.}_key";

in
{
  imports = [ agenix.nixosModules.age ];

  options.nixplusplus."${builtins.baseNameOf ./.}_key" = with lib; mkOption {
    type = types.path;
    description = mdDoc ''
      Path to SSH key to be used to decrypt secrets.
    '';
  };
  options.nixplusplus.${builtins.baseNameOf ./.} = with lib; mkOption {
    type = types.attrsOf (types.submodule ({ ... } @ secret: {
      options = {
        file = mkOption {
          type = types.path;
          description = mdDoc ''
            A path to an encrypted secret.
          '';
        };
        path = mkOption {
          type = types.path;
          readOnly = true;
          description = mdDoc ''
            The path where the secret has been decrypted.
          '';
          apply = _:
            config.age.secrets.${secret.config._module.args.name}.path
          ;
        };
        mode = mkOption {
          type = types.strMatching "[0-7]{3,4}";
          description = mdDoc ''
            Permissions of the decrypted secret, in octal format.
          '';
          default = "0400";
        };
        owner = mkOption {
          type = types.nonEmptyStr;
          description = mdDoc ''
            User that will own the decrypted secret.
          '';
          default = "0";
        };
        group = mkOption {
          type = types.nonEmptyStr;
          description = mdDoc ''
            Group that will own the decrypted secret.
          '';
          default = "0";
        };
      };
    }));
    description = mdDoc ''
      Secrets to be decrypted.
    '';
    default = { };
  };

  config = {
    # Map to agenix configurations.
    age.identityPaths = [ key ];
    age.secrets = builtins.mapAttrs
      (_: secret: builtins.removeAttrs secret [ "path" ])
      secrets
    ;
  };
}
