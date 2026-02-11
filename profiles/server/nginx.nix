{
  pkgs,
  lib,
  ...
}:
let
  package = pkgs.angie;
in
{
  options = {
    services.nginx.virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          config = {
            # quic = true;
            forceSSL = true;
          };
        }
      );
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

      # enableQuicBPF = true;

      appendHttpConfig = ''
        include ${package}/conf/prometheus_all.conf;

        # HSTS
        map $scheme $hsts_header {
          https "max-age=31536000; includeSubdomains; preload";
        }
        add_header Strict-Transport-Security $hsts_header;

        # Disable QUIC
        add_header Alt-Svc "";

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
        # quic = lib.mkForce false;
        forceSSL = lib.mkForce false;
        extraConfig = lib.mkForce "";
      };

      virtualHosts."_" = {
        default = true;
        rejectSSL = true;
        # quic = lib.mkForce false;
        forceSSL = lib.mkForce false;
        locations."/".extraConfig = ''
          return 404;
        '';
      };
    };

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
      interfaces."nebula.averyan".allowedTCPPorts = [ 9114 ];
    };

    # services.prometheus.exporters.nginx.enable = true;
  };
}
