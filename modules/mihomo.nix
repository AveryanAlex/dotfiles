# Mihomo (Clash.Meta) transparent-proxy backend
#
# Wraps nixpkgs `services.mihomo` (DynamicUser, LoadCredential) and enables
# `networking.tproxy` plumbing so mihomo's tproxy-port receives intercepted
# traffic. When `configFile` is null, a placeholder YAML is generated from
# Nix: it makes mihomo start, binds the tproxy port, and lets every flow
# fall through to DIRECT -- useful for verifying end-to-end plumbing before
# wiring a real agenix-managed config.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    recursiveUpdate
    types
    ;

  cfg = config.services.mihomo-tproxy;

  yamlFormat = pkgs.formats.yaml { };

  defaultSettings = {
    mode = "rule";
    log-level = "info";
    ipv6 = true;
    # Bind all top-level listeners (port/socks-port/mixed-port) on 0.0.0.0.
    # Access control happens at the NixOS firewall level, not via mihomo's
    # bind-address or allow-lan. Leave the ports closed in
    # networking.firewall.allowedTCPPorts by default; open per-machine where
    # LAN access is actually wanted.
    allow-lan = true;
    bind-address = "*";

    port = 8080;
    socks-port = 1080;

    # tproxy-port goes through the `listeners:` section instead of the
    # top-level `tproxy-port` key because we need explicit per-listener
    # control. `listen` is omitted so mihomo uses its default, which creates
    # an IPv6 dual-stack socket (::) that accepts both v4 and v6 tproxy
    # deliveries via IPv4-mapped IPv6 addresses. A loopback bind would NOT
    # work for tproxy because a `127.0.0.1:port` socket wouldn't be matched
    # by the kernel's tproxy lookup for non-local destinations.
    listeners = [
      {
        name = "tproxy-in";
        type = "tproxy";
        port = cfg.tproxyPort;
        udp = true;
      }
    ];

    # Loop guard: routing-mark makes mihomo tag its own upstream sockets with
    # the same fwmark, which tproxy.nix's output chain returns on before the
    # mark-set step.
    routing-mark = cfg.tproxyMark;

    # We manage nftables from modules/tproxy.nix. Mihomo must NOT install its
    # own iptables rules or it will fight with ours.
    iptables.enable = false;

    external-controller = "0.0.0.0:9090";

    dns = {
      enable = true;
      listen = "127.0.0.1:1053";
      enhanced-mode = "fake-ip";
      fake-ip-range = "198.18.0.1/16";
      nameserver = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    proxies = [ ];

    proxy-groups = [
      {
        name = "PROXY";
        type = "select";
        proxies = [ "DIRECT" ];
      }
    ];

    rules = [
      "MATCH,DIRECT"
    ];
  };

  mergedSettings = recursiveUpdate defaultSettings cfg.settings;

  generatedConfig = yamlFormat.generate "mihomo.yaml" mergedSettings;
in
{
  options.services.mihomo-tproxy = {
    enable = mkEnableOption "mihomo backend for transparent proxy";

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression ''"''${secrets}/mihomo/desktop.age"'';
      description = ''
        Path to a mihomo YAML config. When null, a placeholder YAML is
        generated from Nix using `settings` and stored world-readable in the
        Nix store (no secrets). Wire an agenix-decrypted path here once you
        have real proxy credentials -- upstream `services.mihomo` reads it via
        systemd `LoadCredential`, so the decrypted file does not need to be
        owned by the mihomo user.
      '';
    };

    tproxyPort = mkOption {
      type = types.port;
      default = config.networking.tproxy.port or 18298;
      defaultText = literalExpression "config.networking.tproxy.port or 18298";
      description = "Port mihomo binds for tproxy interception. Must match networking.tproxy.port.";
    };

    tproxyMark = mkOption {
      type = types.int;
      default = config.networking.tproxy.backendMark or 18299;
      defaultText = literalExpression "config.networking.tproxy.backendMark or 18299";
      description = ''
        fwmark mihomo sets on its own upstream sockets via `routing-mark` /
        SO_MARK. Must match `networking.tproxy.backendMark` so the nft output
        chain skips mihomo's own traffic. Must NOT equal `networking.tproxy.mark`
        or kernel policy routing will loop mihomo's upstream back to itself.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Extra mihomo YAML fragment merged on top of the built-in placeholder
        config via `recursiveUpdate`. Only consulted when `configFile` is null.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.tproxy.enable = true;

    services.mihomo = {
      enable = true;
      webui = pkgs.metacubexd;
      configFile = if cfg.configFile != null then cfg.configFile else generatedConfig;
      # tproxy-port + IP_TRANSPARENT bind + SO_MARK all need CAP_NET_ADMIN in
      # the host user namespace. Upstream's `tunMode` toggle is the only way
      # to get that combination (ambient CAP_NET_ADMIN, PrivateUsers off,
      # AF_NETLINK allowed) without rewriting the whole service unit. The name
      # is misleading -- we are NOT using mihomo's TUN device.
      tunMode = true;
    };
  };
}
