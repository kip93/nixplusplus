{ agenix, ... } @ inputs:
{ config, lib, ... }:
let
  cfg = config.nixplusplus.${builtins.baseNameOf ./.};

in
{
  imports = [ agenix.nixosModules.age ];

  options.nixplusplus.${builtins.baseNameOf ./.} = with lib; {
    key = mkOption {
      type = types.path;
      description = mdDoc ''
        Path to SSH key to be used to decrypt secrets.
      '';
    };
    secrets = mkOption {
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
              The path where the secret has beed decrypted.
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
  };

  config = {
    # Map to agenix configurations.
    age.identityPaths = [ cfg.key ];
    age.secrets = builtins.mapAttrs
      (_: secret: builtins.removeAttrs secret [ "path" ])
      cfg.secrets
    ;
  };

  meta.doc = ./README.md;
}
