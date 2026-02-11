{
  pkgs,
  config,
  ...
}:
{
  services.nextcloud = {
    package = pkgs.nextcloud30;
    hostName = "cloud.neutrino.su";
    https = true;
    appstoreEnable = false;
    database.createLocally = true;
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
    useACMEHost = "neutrino.su";
  };
}
