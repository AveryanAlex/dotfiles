{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    extensions = with pkgs.postgresql_14.pkgs; [ pgvector ];
  };

  systemd.services.postgresql.serviceConfig = {
    MemoryMax = "12G";
    TimeoutStartSec = "10min"; # default 2min is too short for WAL recovery after unclean shutdown
  };

  services.prometheus.exporters.postgres = {
    enable = true;
    runAsLocalSuperUser = true;
  };
  systemd.services.prometheus-postgres-exporter = {
    wants = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    serviceConfig.MemoryMax = "128M";
  };
  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 9187 ];

  persist.state.dirs = [
    {
      directory = "/var/lib/postgresql/14";
      user = "postgres";
      group = "postgres";
      mode = "u=rwx,g=rx,o=";
    }
  ];
}
