let
  name = "cliproxyapi";
  keeperName = "${name}-usage-keeper";
  keeperBasePath = "/usage";
in
{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name} 700 100000 100000 - -"
    "d /persist/${name}/auths 700 100000 100000 - -"
    "d /persist/${name}/logs 700 100000 100000 - -"
    "d /persist/${name}/usage-keeper 700 100000 100000 - -"
  ];

  age.secrets.${name}.file = ./main.age;

  services.nginx.virtualHosts."cli.neutrino.su" = {
    useACMEHost = "neutrino.su";
    forceSSL = true;

    locations."= ${keeperBasePath}".extraConfig = ''
      return 302 ${keeperBasePath}/;
    '';

    locations."${keeperBasePath}/" = {
      proxyPass = "http://10.90.96.3:8080";
      proxyWebsockets = true;

      extraConfig = ''
        proxy_connect_timeout 1h;
        proxy_send_timeout 1h;
        proxy_read_timeout 1h;
        send_timeout 1h;
      '';
    };

    locations."/" = {
      proxyPass = "http://10.90.96.2:8317";
      proxyWebsockets = true;

      extraConfig = ''
        proxy_connect_timeout 1h;
        proxy_send_timeout 1h;
        proxy_read_timeout 1h;
        send_timeout 1h;
      '';
    };
  };

  networking.tproxy.forward."pme-${name}" = { };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers.${name} = {
        containerConfig = {
          image = "docker.io/eceasy/cli-proxy-api:latest";
          autoUpdate = "registry";
          memory = "1g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.96.2";
          volumes = [
            "/persist/${name}/config.yaml:/CLIProxyAPI/config.yaml"
            "/persist/${name}/auths:/root/.cli-proxy-api"
            "/persist/${name}/logs:/CLIProxyAPI/logs"
          ];
          environments = {
            TZ = "Europe/Moscow";
          };
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        serviceConfig = {
          EnvironmentFile = config.age.secrets.${name}.path;
          ExecStartPre = lib.mkBefore [
            (pkgs.writeShellScript "${name}-render-config" ''
              set -eu

              ${pkgs.envsubst}/bin/envsubst \
                < ${./config.yaml} \
                > /persist/${name}/config.yaml

              chmod 600 /persist/${name}/config.yaml
              chown 100000:100000 /persist/${name}/config.yaml
            '')
          ];
        };
      };

      containers.${keeperName} = {
        containerConfig = {
          image = "ghcr.io/willxup/cpa-usage-keeper:latest";
          autoUpdate = "registry";
          memory = "1g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.96.3";
          volumes = [ "/persist/${name}/usage-keeper:/data" ];
          environments = {
            APP_BASE_PATH = keeperBasePath;
            APP_PORT = "8080";
            AUTH_ENABLED = "true";
            CPA_BASE_URL = "http://${name}:8317";
            REDIS_QUEUE_ADDR = "${name}:8317";
            TZ = "Europe/Moscow";
            WORK_DIR = "/data";
          };
          environmentFiles = [ config.age.secrets.${name}.path ];
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        unitConfig = rec {
          Requires = [ "${name}.service" ];
          After = Requires;
        };
      };

      networks.${name}.networkConfig = {
        subnets = [ "10.90.96.0/24" ];
        podmanArgs = [ "--interface-name=pme-${name}" ];
      };
    };
}
