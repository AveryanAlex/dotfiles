{
  config,
  lib,
  ...
}:
{
  services.coredns = {
    enable = true;

    config =
      let
        nullsProxy = domain: ''
          forward ${domain} tls://51.195.92.136 tls://54.38.198.100 tls://79.127.215.166 tls://79.127.215.167 tls://179.43.146.42 {
            tls_servername dns.nullsproxy.com
          }
        '';
        # bind enx2a26a0060857
        common = ''
          bind wan0
          errors
          prometheus
          cache
          any
          ${nullsProxy "supercell.com"}
          ${nullsProxy "clashofclans.com"}
          ${nullsProxy "brawlstars.com"}
          ${nullsProxy "brawlstarsgame.com"}
          # forward . tls://1.1.1.1 tls://1.0.0.1 {
          #   tls_servername cloudflare-dns.com
          #   health_check 15s
          # }
          forward . tls://8.8.8.8
        '';
        certDir = config.security.acme.certs."neutrino.su".directory;
      in
      ''
        . {
          ${common}
        }
        tls://. {
          tls ${certDir}/fullchain.pem ${certDir}/key.pem ${certDir}/chain.pem
          ${common}
        }
      '';
  };
  systemd.services.coredns.serviceConfig.SupplementaryGroups = [ "acme" ];

  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [
    53
    853
  ];

  services.resolved.enable = lib.mkForce false;
  environment.etc."resolv.conf".text = ''
    options edns0
    nameserver 95.165.105.90
  '';
}
