# Xray proxy module
# Provides Xray service configuration for transparent proxying
{
  lib,
  config,
  secrets,
  ...
}:
with lib;
let
  cfg = config.services.xray-tproxy;
in
{
  options.services.xray-tproxy = {
    enable = mkEnableOption "xray backend for transparent proxy";

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the xray configuration file (jsonc format).
        When null, no secret is created and xray uses default config.
        Example: ''${secrets}/xray/desktop.age
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
  };

  config = mkIf cfg.enable {
    # Enable the networking tproxy module
    networking.tproxy.enable = true;

    # Xray service configuration
    services.xray = {
      enable = true;
      settingsFile = mkIf (cfg.configFile != null) config.age.secrets."xray-config.jsonc".path;
    };

    age.secrets."xray-config.jsonc" = mkIf (cfg.configFile != null) {
      file = cfg.configFile;
      owner = "xray";
      group = "xray";
    };

    systemd.services.xray = {
      serviceConfig = {
        DynamicUser = mkForce false;
        User = "xray";
      };
    };

    users.users.xray = {
      isSystemUser = true;
      description = "XRay";
      group = "xray";
      uid = 745;
    };

    users.groups.xray = {
      gid = 745;
    };
  };
}
