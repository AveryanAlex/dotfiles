let
  hostAddress = "95.165.105.90";
  machineAddress = "10.78.0.15";
  sshForwardPort = 17428;
in
{
  systemd.network.networks."40-inoprbr0".dhcpServerStaticLeases = [
    {
      MACAddress = "10:66:6a:74:86:1d";
      Address = machineAddress;
    }
  ];

  systemd.network.networks."40-incusbr0".dhcpServerStaticLeases = [
    {
      MACAddress = "10:66:6a:0e:1d:78";
      Address = "10.77.0.45";
    }
  ];

  networking.nat.forwardPorts = [
    {
      sourcePort = sshForwardPort;
      proto = "tcp";
      destination = "${machineAddress}:22";
      loopbackIPs = [ hostAddress ];
    }
  ];

  networking.firewall.allowedTCPPorts = [ sshForwardPort ];
}
