{ pkgs, ... }:
{
  systemd.sockets.serv1-proxy = {
    description = "Public TCP proxy for serv1 SSH";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "0.0.0.0:3122" ];
  };

  systemd.services.serv1-proxy = {
    description = "Public TCP proxy to serv1 through mole";
    wants = [ "nebula@averyan.service" ];
    after = [ "nebula@averyan.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 10.57.1.42:3122";
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3122 ];
}
