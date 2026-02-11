{ lib, ... }:
{
  # Networkd
  networking.useNetworkd = true;

  # disable legacy DHCP client
  networking.useDHCP = false;

  systemd.services.systemd-networkd.stopIfChanged = false;

  systemd.network.wait-online.enable = lib.mkDefault false;

  # DNS
  services.resolved = {
    enable = true;

    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      FallbackDNS = [ ];
      DNSOverTLS = true;
      Domains = "~.";
    };
  };

  # we use resolved for mDNS
  services.avahi.enable = false;

  systemd.services.systemd-resolved.stopIfChanged = false;

  networking.nameservers = [ "95.165.105.90#dns.neutrino.su" ];

  # Firewall
  networking.nftables = {
    enable = true;
    flushRuleset = false;
  };

  networking.firewall = {
    filterForward = true;
  };

  networking.nat = {
    enable = true;
  };

  # Enable tproxy support
  boot.kernelModules = [ "nft_tproxy" ];
}
