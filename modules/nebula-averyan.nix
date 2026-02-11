{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.networking.nebula-averyan;
in
{
  options = {
    networking.nebula-averyan = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable averyan nebula network.";
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
    users.users.nebula-averyan.uid = 864;

    age.secrets.nebula-averyan-ca = {
      file = ../secrets/nebula/ca-crt.age;
      owner = "nebula-averyan";
    };
    age.secrets.nebula-averyan-key = {
      file = ../secrets/nebula + "/${config.networking.hostName}-key.age";
      owner = "nebula-averyan";
    };
    age.secrets.nebula-averyan-crt = {
      file = ../secrets/nebula + "/${config.networking.hostName}-crt.age";
      owner = "nebula-averyan";
    };

    services.nebula.networks.averyan = {
      package = pkgs.nebula;

      key = config.age.secrets.nebula-averyan-key.path;
      cert = config.age.secrets.nebula-averyan-crt.path;
      ca = config.age.secrets.nebula-averyan-ca.path;

      listen.port = 4242;
      isLighthouse = cfg.isLighthouse;

      lighthouses = mkIf (!cfg.isLighthouse) [ "10.57.1.10" ];
      staticHostMap = {
        "10.57.1.10" = [
          "95.165.105.90:4242"
          "192.168.3.1:4242"
        ];
        "10.57.1.30" = ["192.168.7.155:4242"];
        # "10.57.1.20" = [
        #   "150.241.67.193:4242"
        #   # "10.8.7.1:4242"
        # ];
      };

      settings = {
        lighthouse = {
          remote_allow_list = {
            "0200::/7" = false;
            # "10.8.7.1/32" = true;
          };
        };
        punchy = {
          punch = true;
          respond = true;
        };
        relay = {
          am_relay = cfg.isLighthouse;
          relays = mkIf (!cfg.isLighthouse) [ "10.57.1.10" ];
        };
      };

      firewall = cfg.firewall;
    };
  };
}
