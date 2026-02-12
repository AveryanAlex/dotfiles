{
  pkgs,
  lib,
  config,
  secrets,
  ...
}:
let
  serviceConfig = lib.importJSON ./service.json;
in
{
  age.secrets.credentials-ipfs-cluster.file = "${secrets}/creds/ipfs-cluster.age";

  systemd.services.ipfs-cluster = {
    path = [ pkgs.ipfs-cluster ];
    requires = [ "ipfs.service" ];
    after = [ "ipfs.service" ];
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      if [ ! -f "identity.json" ]; then
        ipfs-cluster-service --config . init -f
      fi
      cp ${builtins.toFile "service.json" (builtins.toJSON serviceConfig)} service.json
      chmod 640 service.json
      sed -i "s/#SECRET#/$SECRET/g" service.json
      # sed -i "s/#BASIC_PASSWORD#/$BASIC_PASSWORD/g" service.json
      # rm -f peerstore
      # ln -sf {builtins.toFile "peerstore" cfg.peers} peerstore
    '';
    script = "ipfs-cluster-service --config . daemon";
    serviceConfig = {
      StateDirectory = "ipfs-cluster";
      EnvironmentFile = config.age.secrets.credentials-ipfs-cluster.path;
      WorkingDirectory = "/var/lib/ipfs-cluster";
      User = "ipfs-cluster";
      Group = "ipfs-cluster";
      PrivateTmp = true;
    };
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/ipfs-cluster";
      user = "ipfs-cluster";
      group = "ipfs-cluster";
      mode = "u=rwx,g=,o=";
    }
  ];

  users = {
    users."ipfs-cluster" = {
      isSystemUser = true;
      description = "IPFS Cluster";
      home = "/var/lib/ipfs-cluster";
      createHome = true;
      group = "ipfs-cluster";
    };

    groups."ipfs-cluster" = { };
  };

  environment.systemPackages = [ pkgs.ipfs-cluster ];

  # networking.firewall.allowedTCPPorts = [ 9094 9096 ];
  # networking.firewall.allowedUDPPorts = [ 9096 ];
}
