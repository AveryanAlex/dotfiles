{
  secrets,
  ...
}:
{
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

  # Whale uses its own xray config
  services.xray-tproxy = {
    enable = true;
    configFile = "${secrets}/xray/whale.age";
  };
}
