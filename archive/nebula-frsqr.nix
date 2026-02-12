{
  lib,
  config,
  pkgs,
  secrets,
  ...
}:
with lib;
let
  cfg = config.networking.nebula-frsqr;
in
{
  options = {
    networking.nebula-frsqr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable frsqr nebula network.";
      };
      isLighthouse = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to configure this node as lighthouse.";
      };
      firewall = {
        outbound = mkOption {
          type = types.listOf types.attrs;
          default = [
            {
              port = "any";
              proto = "any";
              host = "any";
            }
          ];
          description = "Firewall rules for outbound traffic.";
          example = [ ];
        };
        inbound = mkOption {
          type = types.listOf types.attrs;
          default = [
            {
              port = "any";
              proto = "any";
              host = "any";
            }
          ];
          description = "Firewall rules for inbound traffic.";
          example = [ ];
        };
      };
    };
  };

  config = mkIf cfg.enable {
    age.secrets.nebula-ca.file = "${secrets}/nebula-frsqr/ca-crt.age";
    age.secrets.nebula-key.file = "${secrets}/nebula-frsqr" + "/${config.networking.hostName}-key.age";
    age.secrets.nebula-crt.file = "${secrets}/nebula-frsqr" + "/${config.networking.hostName}-crt.age";

    services.nebula.networks.frsqr = {
      package = pkgs.nebula;

      key = config.age.secrets.nebula-key.path;
      cert = config.age.secrets.nebula-crt.path;
      ca = config.age.secrets.nebula-ca.path;

      isLighthouse = cfg.isLighthouse;

      lighthouses = mkIf (!cfg.isLighthouse) [
        "10.3.7.10"
        "10.3.7.11"
      ];
      staticHostMap = {
        "10.3.7.10" = [
          "185.112.83.178:4242"
        ];
        "10.3.7.11" = [
          "89.208.104.77:4242"
        ];
      };

      settings = {
        lighthouse = {
          remote_allow_list = {
            "10.57.0.0/16" = false;
          };
        };
        punchy = {
          punch = true;
          respond = true;
        };
        relay = {
          am_relay = cfg.isLighthouse;
          relays = mkIf (!cfg.isLighthouse) [
            "10.3.7.10"
            "10.3.7.11"
          ];
        };
      };

      firewall = cfg.firewall;
    };
  };
}
