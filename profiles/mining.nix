{
  config,
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = [ pkgs.xmrig ];

  services.xmrig = {
    enable = true;
    settings = {
      autosave = true;
      cpu = true;
      opencl = false;
      cuda = false;
      pools = [
        {
          algo = "rx/0";
          url = "stratum+ssl://randomxmonero.auto.nicehash.com:443";
          user = "NHbV22CpSTtujLKfhXrnpSHT6mxFSB8m3wSi.${config.networking.hostName}";
          pass = "x";
          keepalive = true;
          nicehash = true;
        }
      ];
    };
  };

  systemd.services.xmrig.wantedBy = lib.mkForce [ ];
}
