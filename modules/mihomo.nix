# Mihomo (Clash.Meta) proxy module
# Provides mihomo service configuration for transparent proxying
{
  lib,
  config,
  secrets,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.services.mihomo-tproxy;

  # Default mihomo configuration template with tproxy support
  defaultConfig = {
    port = 7890;
    "socks-port" = 7891;
    "mixed-port" = 7892;
    "redir-port" = 7893;
    "tproxy-port" = cfg.tproxyPort;
    "allow-lan" = true;
    mode = "rule";
    "log-level" = "info";
    "external-controller" = "0.0.0.0:9090";
    "tproxy-mark" = cfg.tproxyMark;
  };

  configFile = pkgs.writeText "mihomo-config.yaml" (builtins.toJSON defaultConfig);
in
{
  options.services.mihomo-tproxy = {
    enable = mkEnableOption "mihomo backend for transparent proxy";

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the mihomo configuration file (YAML format).
        When null, a minimal default config with transparent proxy is used.
        Example: ''${secrets}/mihomo/config.yaml.age
      '';
    };

    tproxyPort = mkOption {
      type = types.port;
      default = config.networking.tproxy.port or 18298;
      defaultText = literalExpression "config.networking.tproxy.port or 18298";
      description = "Port the transparent proxy listens on for connections.";
    };

    tproxyMark = mkOption {
      type = types.int;
      default = config.networking.tproxy.mark or 18298;
      defaultText = literalExpression "config.networking.tproxy.mark or 18298";
      description = "Firewall mark used to avoid loops in traffic redirection.";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Extra configuration options merged with the default mihomo config.
        Only used when configFile is null.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable the networking tproxy module
    networking.tproxy.enable = true;

    # Make sure we have nftables support
    networking.nftables.enable = mkDefault true;

    # Allow mihomo's own ports through firewall
    networking.firewall = {
      allowedTCPPorts = [
        7890
        7891
        7892
        7893
        cfg.tproxyPort
        9090
      ];
      allowedUDPPorts = [ cfg.tproxyPort ];
    };

    # Create mihomo user and group
    users.users.mihomo = {
      isSystemUser = true;
      description = "Mihomo Proxy Service";
      group = "mihomo";
      uid = 746;
    };

    users.groups.mihomo = {
      gid = 746;
    };

    # Systemd service for mihomo
    systemd.services.mihomo = {
      description = "Mihomo (Clash.Meta) Proxy Service";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "mihomo";
        Group = "mihomo";
        ExecStart = "${pkgs.mihomo}/bin/mihomo -f ${
          if cfg.configFile != null then config.age.secrets."mihomo-config.yaml".path else configFile
        }";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        DynamicUser = mkForce false;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = [
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
        ];
        AmbientCapabilities = [
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
        ];

        # Resource limits
        LimitNOFILE = 65535;
        LimitNPROC = 65535;
      };
    };

    # Handle secrets if using custom config
    age.secrets."mihomo-config.yaml" = mkIf (cfg.configFile != null) {
      file = cfg.configFile;
      owner = "mihomo";
      group = "mihomo";
      mode = "600";
    };

    # Ensure required packages are available
    environment.systemPackages = [ pkgs.mihomo ];
  };
}
