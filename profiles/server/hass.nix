{ config, ... }:
let
  hassSliceName = "apps-hass";
  esphomeSliceName = "apps-esphome";
  mkAppServiceConfig = sliceName: {
    Slice = "${sliceName}.slice";
    RestartMode = "direct";
    RestartSec = "5s";
    TimeoutStartSec = "4min";
  };
  appUnitConfig = {
    StartLimitIntervalSec = "10min";
    StartLimitBurst = 6;
  };
in
{
  services.rusticBackup.jobs = {
    hass = {
      paths = [ "/persist/hass/config" ];
      exclude = [
        "/persist/hass/config/zigbee.db"
        "/persist/hass/config/zigbee.db-wal"
        "/persist/hass/config/zigbee.db-shm"
        "/persist/hass/config/zigbee.db-journal"
      ];
      requiresUnits = [
        "hass-db.service"
        "hass.service"
      ];
      runtimePackages = [
        config.virtualisation.podman.package
      ];
      backupStaging = true;
      prepareScript = ''
        podman exec --user postgres hass-db pg_dump \
          --username=hass --no-password --format=custom --compress=0 hass \
          > "$BACKUP_STAGING_DIR/hass.dump"
        podman exec --user root -i hass python3 - <<'PYTHON' > "$BACKUP_STAGING_DIR/zigbee.db"
        import pathlib, shutil, sqlite3, sys, tempfile
        source = pathlib.Path("/config/zigbee.db")
        with tempfile.TemporaryDirectory(prefix=".rustic-", dir=source.parent) as tmp:
            copy = pathlib.Path(tmp) / "backup.db"
            with sqlite3.connect(source.as_uri() + "?mode=ro", uri=True) as src:
                with sqlite3.connect(copy) as dst:
                    src.backup(dst, pages=256)
            with copy.open("rb") as stream:
                shutil.copyfileobj(stream, sys.stdout.buffer, length=1024 * 1024)
        PYTHON
        chown --reference=/persist/hass/config/zigbee.db "$BACKUP_STAGING_DIR/zigbee.db"
        chmod --reference=/persist/hass/config/zigbee.db "$BACKUP_STAGING_DIR/zigbee.db"
      '';
    };
    esphome = {
      paths = [ "/var/lib/esphome" ];
      exclude = [
        "/var/lib/esphome/.esphome/build"
        "/var/lib/esphome/.esphome/platformio"
        "/var/lib/esphome/.esphome/.espressif"
        "/var/lib/esphome/.esphome/.uv_cache"
      ];
    };
  };

  systemd.slices = {
    ${hassSliceName}.description = "Home Assistant application services";
    ${esphomeSliceName}.description = "ESPHome application services";
  };

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
            # runsc cannot proxy the Zigbee adapter's generic serial device.
            podmanArgs = [ "--runtime=crun" ];
            autoUpdate = "registry";
            memory = "4g";
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
          unitConfig = appUnitConfig // rec {
            Requires = [ "hass-db.service" ];
            After = Requires;
          };
          serviceConfig = mkAppServiceConfig hassSliceName;
        };

        hass-db = {
          containerConfig = {
            image = "docker.io/library/postgres:17";
            autoUpdate = "registry";
            memory = "2g";
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
          unitConfig = appUnitConfig;
          serviceConfig = mkAppServiceConfig hassSliceName;
        };

        esphome = {
          containerConfig = {
            image = "ghcr.io/esphome/esphome:latest";
            autoUpdate = "registry";
            memory = "1g";
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
          unitConfig = appUnitConfig;
          serviceConfig = mkAppServiceConfig esphomeSliceName;
        };
      };
      networks = {
        hass = {
          networkConfig = {
            subnets = [ "10.90.18.0/24" ];
            podmanArgs = [ "--interface-name=pme-hass" ];
          };
          serviceConfig.Slice = "${hassSliceName}.slice";
        };
        esphome = {
          networkConfig = {
            subnets = [ "10.90.19.0/24" ];
            podmanArgs = [ "--interface-name=pme-esphome" ];
          };
          serviceConfig.Slice = "${esphomeSliceName}.slice";
        };
      };
    };

  networking.firewall.extraForwardRules = ''
    iifname { pme-esphome, pme-hass } oifname lan0 accept
  '';

  networking.tproxy.forward.pme-hass = { };

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
