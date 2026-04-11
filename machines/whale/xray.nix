# Whale's xray + VLESS ingress commented out 2026-04-11: the ingress
# (t.tb.ru SNI-routed to a VLESS inbound on 127.0.0.1:7443) is no longer
# in use, and mihomo replaces xray for the tproxy outbound role via
# roles/core/mihomo.nix. Left as a comment block for reference.
{
  ...
}:
{
  /*
    services.nginx = {
      defaultSSLListenPort = 3443;

      streamConfig = ''
        map $ssl_preread_server_name $backend {
          t.tb.ru xray;
          musicstream.averyan.ru mtproto;
          default local;
        }

        upstream local {
          server 127.0.0.1:3443;
        }

        upstream xray {
          server 127.0.0.1:7443;
        }

        upstream mtproto {
          server 10.90.94.2:443;
        }

        server {
          listen 443 reuseport so_keepalive=on;
          ssl_preread on;
          proxy_pass $backend;
        }
      '';
    };

    services.xray-tproxy = {
      enable = true;
      configFile = "${secrets}/xray/whale.age";
    };

    systemd.services.xray.serviceConfig = {
      MemoryMax = "256M";
      Restart = "on-failure";
      RestartSec = "10";
    };
  */
}
