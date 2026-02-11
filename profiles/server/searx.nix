{
  config,
  pkgs,
  ...
}:
{
  services.searx = {
    enable = true;
    package = pkgs.searxng;
    settings = {
      server.port = 8278;
      server.bind_address = "0.0.0.0";
      server.secret_key = "@SEARX_SECRET_KEY@";
    };
    environmentFile = config.age.secrets.searx.path;
  };

  age.secrets.searx.file = ../../secrets/creds/searx.age;
}
