{
  pkgs,
  lib,
  ...
}: let
  package = pkgs.angieQuic;
in {
  options = {
    services.nginx.virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        config = {
          quic = true;
          forceSSL = true;
          kTLS = true;
        };
      });
    };
  };

  config = {
    services.nginx = {
      enable = true;
      inherit package;

      clientMaxBodySize = "50000M";

      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      recommendedGzipSettings = true;
      recommendedBrotliSettings = true;
      # recommendedZstdSettings = true;

      enableQuicBPF = true;

      appendHttpConfig = ''
        include ${package}/conf/prometheus_all.conf;

        # HSTS
        map $scheme $hsts_header {
          https "max-age=31536000; includeSubdomains; preload";
        }
        add_header Strict-Transport-Security $hsts_header;

        # QUIC
        add_header Alt-Svc 'h3=":443"; ma=2592000; persist=1';
        # add_header Alt-Svc 'h2=":443"; 'h3=":443"; ma=2592000; persist=1';

        proxy_buffering off;
      '';

      virtualHosts.prometheus = {
        locations."/".extraConfig = ''
          prometheus all;
        '';
        listen = [
          {
            addr = "0.0.0.0";
            port = 9114;
          }
        ];
        quic = lib.mkForce false;
        forceSSL = lib.mkForce false;
        kTLS = lib.mkForce false;
        extraConfig = lib.mkForce '''';
      };
    };

    users.users.nginx.extraGroups = ["acme"];

    networking.firewall = {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [443];
      interfaces."nebula.averyan".allowedTCPPorts = [9114];
    };

    # services.prometheus.exporters.nginx.enable = true;
  };
}
