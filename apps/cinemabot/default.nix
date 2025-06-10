let
  name = "cinemabot";
in
  {config, ...}: {
    systemd.tmpfiles.rules = [
      "d /persist/${name}/data 700 100999 100999 - -"
      "d /persist/${name}/searxng 700 100977 100977 - -"
    ];

    age.secrets."${name}-bot" = {
      file = ./bot.age;
      mode = "600";
      owner = "alex";
    };

    hm.services.podman = {
      networks.${name} = {};

      containers."${name}-bot" = {
        image = "ghcr.io/averyanalex/cinemabot:latest";
        autoUpdate = "registry";
        environmentFile = [config.age.secrets."${name}-bot".path];
        environment = {
          APP__SEARXNG__URL = "http://${name}-searxng:8080/";
        };
        volumes = [
          "/persist/${name}/data:/app/data"
        ];
        network = [
          name
        ];
        extraConfig = {
          Unit = rec {
            Requires = [
              "podman-${name}-searxng.service"
            ];
            After = Requires;
            X-SwitchMethod = "restart";
          };
          Container = {
            GIDMap = "0:1:100000";
            UIDMap = "0:1:100000";
          };
          Service = {
            MemoryHigh = "1G";
            MemoryMax = "2G";
          };
        };
      };

      containers."${name}-searxng" = {
        image = "docker.io/searxng/searxng:latest";
        autoUpdate = "registry";
        volumes = [
          "/persist/${name}/searxng:/etc/searxng"
        ];
        # ports = [
        #   "0.0.0.0:8746:8080"
        # ];
        network = [
          name
        ];
        extraConfig = {
          Unit.X-SwitchMethod = "restart";
          Container = {
            GIDMap = "0:1:100000";
            UIDMap = "0:1:100000";
          };
          # Service = {
          #   MemoryHigh = "2G";
          #   MemoryMax = "3G";
          # };
        };
      };
    };
  }
