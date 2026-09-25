let
  name = "bambuddy";
  sliceName = "apps-${name}";
  hostAddress = "10.57.1.10";
  containerAddress = "10.90.102.2";
  appServiceConfig = {
    Slice = "${sliceName}.slice";
    RestartMode = "direct";
    RestartSec = "5s";
    TimeoutStartSec = "4min";
    TimeoutStopSec = "1min";
  };
  appUnitConfig = {
    StartLimitIntervalSec = "10min";
    StartLimitBurst = 6;
  };
in
{ config, ... }:
{
  services.rusticBackup.jobs.bambuddy = {
    paths = [ "/persist/bambuddy/data" ];
    exclude = [
      "/persist/bambuddy/data/bambuddy.db"
      "/persist/bambuddy/data/bambuddy.db-wal"
      "/persist/bambuddy/data/bambuddy.db-shm"
      "/persist/bambuddy/data/bambuddy.db-journal"
    ];
    requiresUnits = [ "bambuddy.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    prepareScript = ''
      podman exec --user root -i bambuddy python3 - <<'PYTHON' > "$BACKUP_STAGING_DIR/bambuddy.db"
      import pathlib, shutil, sqlite3, sys, tempfile
      source = pathlib.Path("/app/data/bambuddy.db")
      with tempfile.TemporaryDirectory(prefix=".rustic-", dir=source.parent) as tmp:
          copy = pathlib.Path(tmp) / "backup.db"
          with sqlite3.connect(source.as_uri() + "?mode=ro", uri=True) as src:
              with sqlite3.connect(copy) as dst:
                  src.backup(dst, pages=256)
          with copy.open("rb") as stream:
              shutil.copyfileobj(stream, sys.stdout.buffer, length=1024 * 1024)
      PYTHON
      chown --reference=/persist/bambuddy/data/bambuddy.db "$BACKUP_STAGING_DIR/bambuddy.db"
      chmod --reference=/persist/bambuddy/data/bambuddy.db "$BACKUP_STAGING_DIR/bambuddy.db"
    '';
  };

  systemd.slices.${sliceName}.description = "Bambuddy application services";

  systemd.tmpfiles.rules = [
    "d /persist/${name} 700 0 0 - -"
    "d /persist/${name}/data 700 101000 101000 - -"
    "d /persist/${name}/logs 700 101000 101000 - -"
  ];

  services.nginx.virtualHosts."${name}.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${containerAddress}:8000";
      proxyWebsockets = true;
    };
  };

  # The persisted Virtual Printer must bind containerAddress and advertise
  # hostAddress as its remote interface address.
  networking.portForwards.${name} = {
    inputInterface = "nebula.averyan";
    destinationAddress = hostAddress;
    targetAddress = containerAddress;
    tcpPorts = [
      322
      990
      3000
      3002
      8883
      {
        from = 50000;
        to = 50009;
      }
    ];
    udpPorts = [ 2021 ];
  };

  # Bambuddy connects to and scans for physical printers on whale's LAN.
  networking.firewall.extraForwardRules = ''
    iifname "pme-${name}" oifname "lan0" accept
  '';

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers.${name} = {
        containerConfig = {
          image = "ghcr.io/maziggy/bambuddy:latest";
          autoUpdate = "registry";
          memory = "4g";

          networks = [ networks.${name}.ref ];
          ip = containerAddress;
          addCapabilities = [ "NET_BIND_SERVICE" ];

          volumes = [
            "/persist/${name}/data:/app/data"
            "/persist/${name}/logs:/app/logs"
          ];
          environments = {
            HOST = "0.0.0.0";
            PGID = "1000";
            PORT = "8000";
            PUID = "1000";
            TZ = "Europe/Moscow";
            VIRTUAL_PRINTER_PASV_ADDRESS = hostAddress;
          };

          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];

          healthCmd = "curl --fail --silent http://127.0.0.1:8000/health";
          healthInterval = "30s";
          healthTimeout = "10s";
          healthRetries = 3;
          healthStartPeriod = "10s";
          healthOnFailure = "kill";
          notify = "healthy";
          stopTimeout = 30;
        };
        unitConfig = appUnitConfig;
        serviceConfig = appServiceConfig;
      };

      networks.${name} = {
        networkConfig = {
          subnets = [ "10.90.102.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
        serviceConfig.Slice = appServiceConfig.Slice;
      };
    };
}
