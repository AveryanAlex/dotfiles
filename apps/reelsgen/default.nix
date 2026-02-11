{ config, ... }:
let
  name = "reelsgen";

  generatedWorkers = builtins.listToAttrs (
    map
      (branch: {
        name = "${name}-worker-${branch}";
        value = {
          containerConfig = {
            image = "ghcr.io/hao-vc/video-workflow:${branch}";
            autoUpdate = "registry";
            networks = [ config.virtualisation.quadlet.networks.${name}.ref ];
            volumes = [
              "${config.age.secrets."${name}-gsa".path}:/etc/gsa.json:ro"
              "/home/alex/tank/hot/reelsgen/backgrounds:/app/reelsgen-autoposting/config/assets/backgrounds:ro"
              "/home/alex/tank/hot/reelsgen/ads/${branch}:/app/reelsgen-autoposting/config/assets/banners:ro"
            ];
            environments = {
              LOG_LEVEL = "debug";
            };
            environmentFiles = [ config.age.secrets."${name}-env".path ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
          serviceConfig = {
            Environment = [ "REGISTRY_AUTH_FILE=${config.environment.sessionVariables.REGISTRY_AUTH_FILE}" ];
            MemoryMax = "20G";
          };
        };
      })
      [
        "main"
        "spanish"
        "english"
      ]
  );
in
{
  age.secrets."${name}-env" = {
    file = ./env.age;
  };

  age.secrets."${name}-gsa" = {
    file = ./gsa.age;
    owner = "100999";
    group = "100999";
  };

  networking.firewall.interfaces."pme-${name}".allowedTCPPorts = [
    1080 # socks5
    8080 # http proxy
  ];

  virtualisation.quadlet = {
    containers = generatedWorkers;

    networks = {
      ${name}.networkConfig = {
        podmanArgs = [ "--interface-name=pme-${name}" ];
      };
    };
  };
}
