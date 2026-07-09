{ ... }:
let
  mkProxy = upstreamHost: {
    enableACME = true;

    locations."/" = {
      proxyPass = "https://${upstreamHost}";
      proxyWebsockets = true;
      recommendedProxySettings = false;

      extraConfig = ''
        proxy_ssl_server_name on;
        proxy_ssl_name ${upstreamHost};
        proxy_set_header Host ${upstreamHost};

        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Methods;
        proxy_hide_header Access-Control-Allow-Headers;

        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "*" always;
        add_header Access-Control-Allow-Headers "*" always;

        if ($request_method = OPTIONS) {
          return 204;
        }
      '';
    };
  };
in
{
  services.nginx.virtualHosts = {
    "ardupilot-autotest.averylex.dev" = mkProxy "autotest.ardupilot.org";
    "ardupilot-firmware.averylex.dev" = mkProxy "firmware.ardupilot.org";
  };

  security.acme.certs = {
    "ardupilot-autotest.averylex.dev".dnsProvider = null;
    "ardupilot-firmware.averylex.dev".dnsProvider = null;
  };
}
