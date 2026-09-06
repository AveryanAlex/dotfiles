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
      # Keep resolved as the system stub and route all unicast DNS through
      # mihomo's loopback listener.
      DNS = [ "127.0.0.1:1053" ];
      # Mihomo's DNS proxy does not preserve the signatures required for
      # systemd-resolved to validate DNSSEC responses.
      DNSSEC = false;
      FallbackDNS = [ ];
      # The local resolved -> mihomo hop is plain DNS. Upstream encryption,
      # when desired, is configured in mihomo itself.
      DNSOverTLS = false;
      Domains = [ "~." ];
    };
  };

  # we use resolved for mDNS
  services.avahi.enable = false;

  systemd.services.systemd-resolved.stopIfChanged = false;

  # NTP
  networking.timeServers = [
    "92.255.126.1"
    "92.255.126.4"
    "89.109.251.22"
    "194.190.168.1"
  ];

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
