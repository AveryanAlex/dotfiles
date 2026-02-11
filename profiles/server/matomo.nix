{
  pkgs,
  lib,
  ...
}:
{
  services.matomo = {
    enable = true;
    package = pkgs.matomo;
    nginx = {
      enableACME = false;
      useACMEHost = "neutrino.su";
      # quic = lib.mkForce true;
      # kTLS = lib.mkForce true;
      extraConfig = ''
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
      '';
    };
    hostname = "matomo.neutrino.su";
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/matomo";
      user = "matomo";
      group = "matomo";
      mode = "u=rwx,g=,o=";
    }
  ];
}
