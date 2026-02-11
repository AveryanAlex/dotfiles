{
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      DOMAIN = "https://bw.neutrino.su";
      DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
      ROCKET_ADDRESS = "::";
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
  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 8222 ];

  systemd.services.vaultwarden = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
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
