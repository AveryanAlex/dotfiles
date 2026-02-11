{ lib, ... }:
{
  services.nginx = {
    defaultSSLListenPort = 3443;

    streamConfig = ''
      map $ssl_preread_server_name $backend {
        t.tb.ru xray;
        default local;
      }

      upstream local {
        server 127.0.0.1:3443;
      }

      upstream xray {
        server 127.0.0.1:7443;
      }

      server {
        listen 443 reuseport so_keepalive=on;
        ssl_preread on;
        proxy_pass $backend;
      }
    '';
  };

  age.secrets."xray-config.jsonc".file = lib.mkForce ../../secrets/xray/whale.age;
}
