{
  services.grafana = {
    enable = true;

    settings = {
      database = {
        type = "postgres";
        user = "grafana";
        name = "grafana";
        host = "/run/postgresql";
      };
      server = {
        http_addr = "0.0.0.0";
        http_port = 3729;
        domain = "grafana.averyan.ru";
        rootUrl = "https://grafana.averyan.ru/";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090/";
        }
        {
          name = "BVI Love";
          type = "postgres";
          database = "bvilove";
          user = "grafana";
          url = "/run/postgresql";
        }
      ];
    };
  };

  systemd.services.grafana = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services.postgresql = {
    ensureDatabases = [ "grafana" ];
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
  };

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 3729 ];

  services.prometheus = {
    enable = true;

    listenAddress = "127.0.0.1";
    scrapeConfigs = [
      {
        job_name = "prometheus";
        scrape_interval = "1m";
        static_configs = [
          {
            targets = [ "localhost:9090" ];
          }
        ];
      }
      {
        job_name = "node";
        scrape_interval = "1m";
        static_configs = [
          {
            targets = [
              "alligator:9100"
              "diamond:9100"
              "falcon:9100"
              "grizzly:9100"
              "hamster:9100"
              "hawk:9100"
              "whale:9100"
            ];
          }
        ];
      }
      {
        job_name = "angie";
        scrape_interval = "1m";
        static_configs = [
          {
            targets = [
              "whale:9114"
            ];
          }
        ];
      }
      {
        job_name = "postgres";
        scrape_interval = "1m";
        static_configs = [
          {
            targets = [
              "whale:9187"
            ];
          }
        ];
      }
      {
        job_name = "wireguard";
        scrape_interval = "1m";
        static_configs = [
          {
            targets = [
              "hawk:9586"
            ];
          }
        ];
      }
      # {
      #   job_name = "tor";
      #   scrape_interval = "1m";
      #   static_configs = [
      #     {
      #       targets = [
      #         "hawk:9130"
      #       ];
      #     }
      #   ];
      # }
      {
        job_name = "influxdb";
        scrape_interval = "1m";
        static_configs = [
          {
            targets = [
              "grizzly:8086"
            ];
          }
        ];
      }
      {
        job_name = "nut";
        scrape_interval = "1m";
        metrics_path = "/ups_metrics";
        static_configs = [
          {
            targets = [
              "whale:9199"
            ];
          }
        ];
      }
      {
        job_name = "automm";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "grizzly:9521"
            ];
          }
        ];
      }
      {
        job_name = "coredns";
        scrape_interval = "1m";
        static_configs = [
          {
            targets = [
              "127.0.0.1:9153"
            ];
          }
        ];
      }
    ];
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/prometheus2";
      user = "prometheus";
      group = "prometheus";
      mode = "u=rwx,g=,o=";
    }
    {
      directory = "/var/lib/grafana";
      user = "grafana";
      group = "grafana";
      mode = "u=rwx,g=,o=";
    }
  ];
}
