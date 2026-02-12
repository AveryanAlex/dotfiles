{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/hass/config 700 100000 100000 - -"
    "d /persist/hass/db 700 100999 100999 - -"
  ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        hass = {
          containerConfig = {
            image = "ghcr.io/home-assistant/home-assistant:stable";
            autoUpdate = "registry";
            networks = [ networks.hass.ref ];
            ip = "10.90.18.2";
            volumes = [
              "/persist/hass/config:/config"
              # "/run/dbus:/run/dbus:ro"
              # "/dev:/dev"
            ];
            devices = [
              "/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20221201192411-if00"
            ];
            addCapabilities = [
              "NET_RAW"
              "NET_ADMIN"
            ];
            environments = {
              TZ = "Europe/Moscow";
            };
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
          unitConfig = rec {
            Requires = [ "hass-db.service" ];
            After = Requires;
          };
        };

        hass-db = {
          containerConfig = {
            image = "docker.io/library/postgres:17";
            autoUpdate = "registry";
            networks = [ networks.hass.ref ];
            ip = "10.90.18.3";
            volumes = [ "/persist/hass/db:/var/lib/postgresql/data" ];
            environments = {
              POSTGRES_USER = "hass";
              POSTGRES_PASSWORD = "hass";
              POSTGRES_DB = "hass";
            };
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
        };

        esphome = {
          containerConfig = {
            image = "ghcr.io/esphome/esphome:latest";
            autoUpdate = "registry";
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "/var/lib/esphome:/config"
            ];
            # ports = [ "whale:6052:6052" ];
            networks = [ networks.esphome.ref ];
            ip = "10.90.19.2";
            environments = {
              ESPHOME_DASHBOARD_USE_PING = "true";
              TZ = "Europe/Moscow";
            };
            # gidMaps = [ "0:100000:100000" ];
            # uidMaps = [ "0:100000:100000" ];
          };
          # unitConfig = rec {
          #   Requires = [ "postgresql.service" ];
          #   After = Requires;
          # };
        };
      };
      networks = {
        hass.networkConfig = {
          subnets = [ "10.90.18.0/24" ];
          podmanArgs = [ "--interface-name=pme-hass" ];
        };
        esphome.networkConfig = {
          subnets = [ "10.90.19.0/24" ];
          podmanArgs = [ "--interface-name=pme-esphome" ];
        };
      };
    };

  networking.firewall.extraForwardRules = ''
    iifname { pme-esphome, pme-hass } oifname lan0 accept
  '';

  networking.tproxy.forward.interfaces = [ "pme-hass" ];

  # systemd.services."podman-esphome".after = ["network-online.target"];
  # services.esphome = {
  #   enable = true;
  #   address = "0.0.0.0";
  # };
  # systemd.services.esphome.serviceConfig = {
  #   DynamicUser = lib.mkForce false;
  #   NoNewPrivileges = true;
  #   PrivateTmp = true;
  #   RemoveIPC = true;
  #   RestrictSUIDSGID = true;
  # };

  # services.postgresql = {
  #   ensureDatabases = [ "hass" ];
  #   ensureUsers = [
  #     {
  #       name = "hass";
  #       ensureDBOwnership = true;
  #     }
  #   ];
  # };

  persist.state.dirs = [
    # {
    #   directory = "/var/lib/hass";
    #   user = "hass";
    #   group = "hass";
    #   mode = "u=rwx,g=,o=";
    # }
    {
      directory = "/var/lib/esphome";
      user = "esphome";
      group = "esphome";
      mode = "0750";
    }
  ];

  # networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [
  #   8123
  #   6052
  # ];
}
