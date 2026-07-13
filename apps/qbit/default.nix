let
  name = "qbit";
in
{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/config 700 1000 100 - -"
  ];

  services.nginx.virtualHosts."qbit.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.84.2:8173";
      proxyWebsockets = true;
    };
  };

  networking.tproxy.forward."pme-${name}" = {
    # Proxy only HTTP(S) tracker/webseed traffic; keep BitTorrent peer and
    # DHT/UDP traffic direct.
    tcp = [
      80
      443
    ];
    udp = [ ];
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        ${name} = {
          serviceConfig = {
            ExecStartPre = lib.mkBefore [
              (pkgs.writeShellScript "${name}-cleanup-locks" ''
                set -eu

                rm -f \
                  /persist/${name}/config/qBittorrent/lockfile \
                  /persist/${name}/config/qBittorrent/ipc-socket
              '')
            ];
            TimeoutStopSec = "120s";
          };

          containerConfig = {
            image = "lscr.io/linuxserver/qbittorrent:latest";
            autoUpdate = "registry";
            memory = "8g";
            stopTimeout = 60;
            networks = [ networks.${name}.ref ];
            ip = "10.90.84.2";
            volumes = [
              "/persist/${name}/config:/config"
              "/home/alex/tank/hot/Downloads:/home/alex/tank/hot/Downloads"
              "/home/alex/tank/Torrents:/home/alex/tank/Torrents"
              "/home/alex/tank/Import/Torrent:/home/alex/tank/Import/Torrent"
            ];
            environments = {
              PUID = "1000";
              PGID = "100";
              TZ = "Europe/Moscow";
              WEBUI_PORT = "8173";
            };
            # container gid 100 -> host 100 so PGID=100 matches your group
            gidMaps = [
              "0:100000:100"
              "100:100:1"
              "101:100101:98999"
            ];
            uidMaps = [
              "0:100000:1000"
              "1000:1000:1"
              "1001:101001:98999"
            ];
          };
        };
      };

      networks = {
        ${name}.networkConfig = {
          subnets = [ "10.90.84.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
      };
    };

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 8173 ];

  networking.nat.forwardPorts =
    let
      common = {
        destination = "10.90.84.2:12813";
        sourcePort = 12813;
        loopbackIPs = [ "95.165.105.90" ];
      };
    in
    [
      (common // { proto = "tcp"; })
      (common // { proto = "udp"; })
    ];

  networking.firewall.allowedTCPPorts = [ 12813 ];
  networking.firewall.allowedUDPPorts = [ 12813 ];
}
