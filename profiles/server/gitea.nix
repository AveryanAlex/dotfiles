{
  services.gitea = {
    enable = true;
    settings = {
      server = {
        ROOT_URL = "https://git.averyan.ru/";
        HTTP_PORT = 3816;
        DOMAIN = "git.averyan.ru";
        SSH_PORT = 7322;
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
    };
    lfs.enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/gitea";
      user = "gitea";
      group = "gitea";
      mode = "u=rwx,g=rx,o=";
    }
  ];
  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [
    3816
    7322
  ];

  systemd.services.gitea = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
