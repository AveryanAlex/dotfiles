{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.roles.server
    inputs.self.nixosModules.hardware.ec2

    inputs.self.nixosModules.profiles.server.automm
    inputs.self.nixosModules.profiles.server.acme
    inputs.self.nixosModules.profiles.server.nginx

    ./influxdb.nix
  ];

  boot.kernel.sysctl = {
    # "net.ipv4.tcp_low_latency" = 1;
    "net.core.rmem_default" = 1048576;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_default" = 1048576;
    "net.core.wmem_max" = 16777216;
    "net.core.optmem_max" = 65536;
    # "net.ipv4.tcp_rmem" = "4096 1048576 2097152";
    "net.ipv4.tcp_rmem" = "4096 1048576 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_mtu_probing" = 1;
  };

  systemd.services.systemd-timesyncd.serviceConfig = {
    CPUSchedulingPolicy = "rr";
    CPUSchedulingPriority = 60;
  };

  # systemd.extraConfig = "CPUAffinity=0";
  # systemd.services.automm.serviceConfig.CPUAffinity = "1-3";

  networking = {
    hosts = {
      # "172.64.144.82" = ["ws.okx.com"];
      # "104.17.101.83" = ["ws.poloniex.com"];
      # mexc has good defaults
      # "18.65.168.77" = ["ws-api-spot.kucoin.com"];
      # "104.18.33.108" = ["api.kucoin.com"];
      # "104.17.188.205" = ["ws.kraken.com"];
      # huobi has good defaults
      # TODO: gateio api.gateio.ws
      # "99.84.133.10" = ["stream.bybit.com"];
    };
  };

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 9521 ];

  networking.interfaces.ens5.useDHCP = true;
  networking.nameservers = lib.mkForce [ ];
  system.stateVersion = "23.11";
}
