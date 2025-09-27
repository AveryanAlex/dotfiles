{ pkgs, ... }:
{
  systemd.services.qbittorrent = {
    after = [ "network.target" ];
    description = "Qbittorrent Web";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.qbittorrent-nox ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8173
      '';
      User = "alex";
      Group = "users";
      MemoryMax = "8G";
      Restart = "always";
    };
  };

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 8173 ];

  networking.firewall.allowedTCPPorts = [ 12813 ];
  networking.firewall.allowedUDPPorts = [ 12813 ];

  persist.state.homeDirs = [
    ".config/qBittorrent"
    ".local/share/qBittorrent"
  ];
}
