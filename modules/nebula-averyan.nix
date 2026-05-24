{
  lib,
  config,
  pkgs,
  secrets,
  ...
}:
with lib;
let
  cfg = config.networking.nebula-averyan;
  # Keep fixed Nebula ports unique per host. Mihomo's UDP TProxy writeback
  # path can collide with local wildcard listeners when a node listens on the
  # same port as the remote peer it is dialing.
  listenPorts = {
    whale = 4242;
    falcon = 42020;
    hawk = 42021;
    lizard = 42030;
    beaver = 42031;
    alligator = 42040;
    hamster = 42041;
    diamond = 42050;
    grizzly = 42060;
    ferret = 42070;
  };
  defaultListenPort = attrByPath [ config.networking.hostName ] (
    if cfg.isLighthouse then 4242 else 0
  ) listenPorts;
  effectiveListenPort = if cfg.listenPort != null then cfg.listenPort else defaultListenPort;
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
      listenPort = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = ''
          UDP port Nebula binds for handshakes. null means the module's
          deterministic per-host port, falling back to 4242 for unknown
          lighthouses and an ephemeral port for unknown roaming nodes.
        '';
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
    # Do not globally bypass Nebula's UDP port in tproxy: some paths need to
    # go through the RU whitelist proxies. Known nodes use unique fixed ports
    # instead, so LAN peers can pass firewall rules while mihomo's UDP TProxy
    # writeback socket does not collide with another wildcard listener on the
    # same port.
    # networking.tproxy.skipPorts.any = [ 4242 ];

    networking.firewall.allowedUDPPorts = optional (effectiveListenPort != 0) effectiveListenPort;

    users.users.nebula-averyan.uid = 864;

    age.secrets.nebula-averyan-ca = {
      file = "${secrets}/nebula/ca-crt.age";
      owner = "nebula-averyan";
    };
    age.secrets.nebula-averyan-key = {
      file = "${secrets}/nebula" + "/${config.networking.hostName}-key.age";
      owner = "nebula-averyan";
    };
    age.secrets.nebula-averyan-crt = {
      file = "${secrets}/nebula" + "/${config.networking.hostName}-crt.age";
      owner = "nebula-averyan";
    };

    systemd.services."nebula@averyan".before = [ "network-online.target" ];
    systemd.services."nebula@averyan".wantedBy = [ "network-online.target" ];
    systemd.services."nebula@averyan".serviceConfig.MemoryMax = "256M";

    services.nebula.networks.averyan = {
      package = pkgs.nebula;

      key = config.age.secrets.nebula-averyan-key.path;
      cert = config.age.secrets.nebula-averyan-crt.path;
      ca = config.age.secrets.nebula-averyan-ca.path;

      listen.port = effectiveListenPort;
      isLighthouse = cfg.isLighthouse;

      lighthouses = mkIf (!cfg.isLighthouse) [ "10.57.1.10" ];
      staticHostMap = {
        "10.57.1.10" = [
          "95.165.105.90:4242"
          "192.168.3.1:4242"
        ];
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
