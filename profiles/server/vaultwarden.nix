{ config, ... }:
{
  services.rusticBackup.jobs.vaultwarden = {
    paths = [ "/var/lib/bitwarden_rs" ];
    requiresUnits = [ "postgresql.service" ];
    runtimePackages = [ config.services.postgresql.package ];
    backupStaging = true;
    prepareScript = ''
      # Let rustic handle compression and deduplication of the dump.
      runuser -u postgres -- pg_dump \
        --host=/run/postgresql --no-password \
        --format=custom --compress=0 vaultwarden \
        > "$BACKUP_STAGING_DIR/vaultwarden.dump"
    '';
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      DOMAIN = "https://bw.neutrino.su";
      DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
    };
  };

  users.users.vaultwarden.uid = 993;
  users.groups.vaultwarden.gid = 989;

  persist.state.dirs = [
    {
      directory = "/var/lib/bitwarden_rs";
      user = "vaultwarden";
      group = "vaultwarden";
      mode = "u=rwx,g=,o=";
    }
  ];
  # networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 8222 ];

  systemd.services.vaultwarden = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    serviceConfig.MemoryMax = "512M";
  };

  services.postgresql = {
    ensureDatabases = [ "vaultwarden" ];
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
    ];
  };
}
