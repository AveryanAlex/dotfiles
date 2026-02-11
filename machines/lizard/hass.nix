let
  name = "hass";
in
{
  systemd.tmpfiles.rules = [
    "d /data/${name}/config 700 0 0 - -"
  ];

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 8123 ];

  virtualisation.quadlet = {
    containers = {
      "${name}" = {
        containerConfig = {
          image = "ghcr.io/home-assistant/home-assistant:stable";
          autoUpdate = "registry";
          networks = [ "host" ];
          podmanArgs = [ "--privileged" ];
          volumes = [
            "/data/${name}/config:/config"
            "/run/dbus:/run/dbus:ro"
            "/dev:/dev"
          ];
          environments = {
            TZ = "Europe/Moscow";
          };
        };
      };
    };
  };
}
