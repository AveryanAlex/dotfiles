# Mihomo personal preferences (akenai subscription, proxy groups, rule
# providers, rule list, DNS, sniffer) shared across all machines. The
# mihomo-tproxy module (modules/mihomo.nix) owns infrastructure defaults
# (ports, routing-mark, tproxy listener, iptables.enable=false, upstream
# services.mihomo wiring). This file layers the user's policy on top.
#
# Every machine that imports roles/core gets mihomo enabled. Desktops also
# enable `networking.tproxy.output.enable` in roles/desktop to make mihomo
# actually intercept their outbound traffic. On servers/family machines,
# mihomo runs as a plain listener (http proxy on 127.0.0.1:8080, socks on
# 127.0.0.1:1080) without touching host traffic -- explicit clients can
# still point at it.
{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:
let
  # Overlay metacubexd so its config.js sets defaultBackendURL to
  # window.location.origin. Without this, the dashboard's bundled fallback
  # is a hardcoded http://127.0.0.1:9090, which breaks when you open the UI
  # from any nebula peer. `runCommand` is cheap here -- it just copies the
  # upstream package and rewrites one ~80-byte file.
  metacubexdAuto = pkgs.runCommand "metacubexd-auto" { } ''
    cp -r ${pkgs.metacubexd} $out
    chmod -R +w $out
    cat > $out/config.js <<'EOF'
    window.__METACUBEXD_CONFIG__ = {
      defaultBackendURL: window.location.origin,
    };
    EOF
  '';
in
{
  config = lib.mkMerge [
    {
      services.mihomo-tproxy.enable = lib.mkDefault true;
    }

    (lib.mkIf config.services.mihomo-tproxy.enable {
      services.mihomo-tproxy.settings = {
        # DNS config mirrors the upstream akenai yaml. `listen: ""` disables
        # the external DNS listener entirely so apps on the host continue to
        # use systemd-resolved -- this config only drives mihomo's own
        # internal resolution (rule-sets, sniffed domains resolved for rule
        # matching, proxy-server hostnames, DIRECT-routed domain lookups).
        dns = {
          listen = "";
          ipv6 = true;
          use-hosts = true;
          respect-rules = true;
          enhanced-mode = "normal";
          default-nameserver = [
            "8.8.8.8"
            "8.8.4.4"
          ];
          proxy-server-nameserver = [
            "8.8.8.8"
            "8.8.4.4"
          ];
          nameserver = [
            "8.8.8.8"
            "8.8.4.4"
          ];
          direct-nameserver = [ "77.88.8.8#DIRECT" ];
        };

        # Sniff HTTP Host / TLS SNI / QUIC SNI so domain-based rules can
        # match traffic that only carries an IP by the time it reaches
        # mihomo via tproxy. override-destination=false keeps the original
        # IP as the upstream dial target and only uses the sniffed hostname
        # for rule matching.
        sniffer = {
          enable = true;
          sniff = {
            HTTP.ports = [ 80 ];
            TLS = {
              override-destination = false;
              ports = [
                443
                853
                8443
              ];
            };
          };
        };

        proxy-providers.akenai = {
          type = "http";
          # Placeholder substituted at service start by envsubst reading the
          # agenix-decrypted EnvironmentFile. See systemd override below.
          url = "\${AKENAI_URL}";
          path = "./proxy_providers/akenai.yaml";
          interval = 86400;
          proxy = "DIRECT";
          health-check = {
            enable = true;
            url = "https://www.gstatic.com/generate_204";
            interval = 300;
            timeout = 15000;
            lazy = false;
            expected-status = 204;
          };
          override = {
            udp = true;
            udp-over-tcp = false;
          };
        };

        # Group naming: non-akenai groups are English; akenai-provided
        # proxy names (the country labels like "🇩🇪 Германия") stay as-is
        # because they come from the provider.
        #
        # Groups that reference akenai's proxies cannot list them by name
        # in `proxies:` -- that field only resolves top-level proxies and
        # other groups. Use `use: [akenai]` (+ filter) to pull specific
        # proxies out of the provider. `filter` is a regex; we use unique
        # substrings of display names, which are sufficient because nothing
        # else in the provider list shares those substrings.
        proxy-groups = [
          # Default is the MATCH-rule target. First member (Proxy) is the
          # initial pick on fresh machines. Switching it to DIRECT turns
          # mihomo into a transparent pass-through; switching to REJECT
          # becomes a kill-switch.
          {
            name = "Default";
            type = "select";
            interval = 300;
            url = "https://www.gstatic.com/generate_204";
            proxies = [
              "Proxy"
              "DIRECT"
              "REJECT"
            ];
          }
          {
            name = "Proxy";
            type = "select";
            interval = 300;
            url = "https://www.gstatic.com/generate_204";
            # Auto is listed first, so fresh machines default to
            # latency-based auto-pick. Dashboard still lets you pin a
            # specific country for debugging.
            proxies = [ "Auto" ];
            use = [ "akenai" ];
          }
          # Auto is a fallback group: iterates its member list
          # top-to-bottom and picks the first one that's alive. Ordered
          # preference: Sweden first, then Germany, then whichever of the
          # remaining EU whitelist is reachable (in akenai provider order).
          # `fallback` can't reference provider proxies by name, so
          # Sweden/Germany are pinned via tiny hidden select groups that
          # each wrap a single filtered akenai proxy; the trailing
          # `use: [akenai] + filter` appends the rest.
          {
            name = "Auto";
            type = "fallback";
            url = "https://www.gstatic.com/generate_204";
            interval = 300;
            lazy = true;
            proxies = [
              "__Sweden"
              "__Germany"
            ];
            use = [ "akenai" ];
            filter = "Финляндия|Австрия|Чехия|Нидерланды";
          }
          {
            name = "__Sweden";
            type = "select";
            hidden = true;
            use = [ "akenai" ];
            filter = "Швеция";
          }
          {
            name = "__Germany";
            type = "select";
            hidden = true;
            use = [ "akenai" ];
            filter = "Германия";
          }
          # Dedicated latency-based group for Telegram. Probes
          # core.telegram.org so the elected node reflects actual Telegram
          # RTT rather than gstatic's CDN (which can mislead if a proxy is
          # close to Google but far from Telegram's DCs). Whitelist is the
          # same 6 EU countries.
          {
            name = "Telegram";
            type = "url-test";
            url = "https://core.telegram.org/";
            expected-status = "200";
            interval = 300;
            tolerance = 30;
            lazy = true;
            use = [ "akenai" ];
            filter = "Германия|Швеция|Финляндия|Австрия|Чехия|Нидерланды";
          }
          {
            name = "RU Sites";
            type = "select";
            interval = 300;
            url = "https://www.gstatic.com/generate_204";
            proxies = [
              "DIRECT"
              "Proxy"
            ];
            use = [ "akenai" ];
            filter = "Россия";
          }
          {
            name = "YouTube";
            type = "select";
            interval = 300;
            url = "https://www.gstatic.com/generate_204";
            proxies = [ "Proxy" ];
            use = [ "akenai" ];
            filter = "Глобальный YouTube";
          }
        ];

        rule-providers = {
          geosite-ru = {
            type = "http";
            behavior = "domain";
            format = "mrs";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/category-ru.mrs";
            path = "./geosite-ru.mrs";
            interval = 86400;
          };
          geoip-ru = {
            type = "http";
            behavior = "ipcidr";
            format = "mrs";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/ru.mrs";
            path = "./geoip-ru.mrs";
            interval = 86400;
          };
          geosite-private = {
            type = "http";
            behavior = "domain";
            format = "mrs";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs";
            path = "./geosite-private.mrs";
            interval = 86400;
          };
          geoip-private = {
            type = "http";
            behavior = "ipcidr";
            format = "mrs";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/private.mrs";
            path = "./geoip-private.mrs";
            interval = 86400;
          };
          geosite-youtube = {
            type = "http";
            behavior = "domain";
            format = "mrs";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/youtube.mrs";
            path = "./geosite-youtube.mrs";
            interval = 86400;
          };
          geosite-telegram = {
            type = "http";
            behavior = "domain";
            format = "mrs";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/telegram.mrs";
            path = "./geosite-telegram.mrs";
            interval = 86400;
          };
          geoip-telegram = {
            type = "http";
            behavior = "ipcidr";
            format = "mrs";
            url = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/telegram.mrs";
            path = "./geoip-telegram.mrs";
            interval = 86400;
          };
          torrent-clients = {
            type = "http";
            behavior = "classical";
            format = "yaml";
            url = "https://raw.githubusercontent.com/legiz-ru/mihomo-rule-sets/main/other/torrent-clients.yaml";
            path = "./torrent-clients.yaml";
            interval = 86400;
          };
        };

        rules = [
          "RULE-SET,geoip-private,DIRECT,no-resolve"
          "RULE-SET,geosite-private,DIRECT"
          "AND,((NETWORK,udp),(DST-PORT,443)),REJECT"
          "RULE-SET,torrent-clients,DIRECT"
          "RULE-SET,geosite-telegram,Telegram"
          "RULE-SET,geoip-telegram,Telegram,no-resolve"
          "RULE-SET,geosite-youtube,YouTube"
          "RULE-SET,geosite-ru,RU Sites"
          "RULE-SET,geoip-ru,RU Sites"
          "MATCH,Default"
        ];
      };

      # Expose the mihomo external-controller (REST API + metacubexd
      # dashboard) to the nebula-averyan overlay only. Everything else
      # (LAN, WAN) stays blocked by the default firewall. Other mihomo
      # listeners (8080/1080/18298) remain closed until you explicitly
      # add them here.
      networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 9090 ];

      # Agenix-encrypted `AKENAI_URL=...` line. systemd loads it as an
      # EnvironmentFile on mihomo.service; the ExecStartPre script below
      # runs envsubst over the generated yaml (which contains the literal
      # "${AKENAI_URL}" placeholder) and writes the resolved config to a
      # tmpfs runtime dir. Mihomo loads that resolved file via ExecStart
      # override.
      age.secrets.mihomo-akenai-url.file = "${secrets}/mihomo/akenai-url.age";

      systemd.services.mihomo.serviceConfig = {
        RuntimeDirectory = "mihomo";
        RuntimeDirectoryMode = "0700";
        EnvironmentFile = config.age.secrets.mihomo-akenai-url.path;
        ExecStartPre = lib.mkBefore [
          # No `+` prefix: runs as the service's DynamicUser, which owns
          # RuntimeDirectory (/run/mihomo) and can therefore write the
          # resolved config there. Running as root would create a
          # root-owned file that the DynamicUser cannot read.
          (pkgs.writeShellScript "mihomo-envsubst" ''
            set -eu
            ${pkgs.envsubst}/bin/envsubst '$AKENAI_URL' \
              < "$CREDENTIALS_DIRECTORY/config.yaml" \
              > /run/mihomo/config.yaml
          '')
        ];
        ExecStart = lib.mkForce (
          lib.concatStringsSep " " [
            (lib.getExe config.services.mihomo.package)
            "-d /var/lib/private/mihomo"
            "-f /run/mihomo/config.yaml"
            "-ext-ui ${metacubexdAuto}"
          ]
        );
      };
    })
  ];
}
