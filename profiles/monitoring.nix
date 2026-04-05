{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "buddyinfo"
      "ksmd"
      "mountstats"
      "processes"
      "qdisc"
      "systemd"
      "tcpstat"
    ];
  };

  systemd.services.prometheus-node-exporter.serviceConfig.MemoryMax = "128M";

  # networking.firewall.allowedTCPPorts = [9100];
  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 9100 ];
}
