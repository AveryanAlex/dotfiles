{
  pkgs,
  lib,
  config,
  ...
}:
let
  clientConfig = {
    "m.homeserver" = {
      base_url = "https://matrix.neutrino.su";
      server_name = "neutrino.su";
    };
    "m.identity_server".base_url = "https://vector.im";
    "org.matrix.msc3575.proxy"."url" = "https://syncv3.neutrino.su";
  };
  serverConfig."m.server" = "matrix.neutrino.su:443";
  mkWellKnown = data: ''
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  services.nginx = {
    virtualHosts = {
      "neutrino.su" = {
        useACMEHost = "neutrino.su";
        locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
        locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
      };
      "matrix.neutrino.su" = {
        useACMEHost = "neutrino.su";
        locations."/_matrix".proxyPass = "http://[::1]:8008";
        locations."/_synapse/client".proxyPass = "http://[::1]:8008";
        locations."/telegram".proxyPass = "http://127.0.0.1:8194/public/";
        locations."/".extraConfig = ''
          return 404;
        '';
      };
      "syncv3.neutrino.su" = {
        useACMEHost = "neutrino.su";
        locations."/".proxyPass = "http://127.0.0.1:8009";
        locations."/".proxyWebsockets = true;
      };
      "element.neutrino.su" = {
        useACMEHost = "neutrino.su";
        root = pkgs.element-web.override {
          conf = {
            default_server_config = clientConfig;
          };
        };
      };
    };
  };

  age.secrets.matrix = {
    file = ../../secrets/creds/matrix.age;
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };

  fileSystems."/var/lib/matrix-synapse/media_store" = {
    device = "UUID=bcfa404a-68de-4a25-9fb0-4e972c8f9423";
    fsType = "btrfs";
    options = [
      "compress=zstd:7"
      "noatime"
      "subvol=@matrix-media"
    ];
  };

  services.matrix-synapse = {
    enable = true;
    extraConfigFiles = [
      config.age.secrets.matrix.path
    ];
    settings = {
      server_name = "neutrino.su";
      public_baseurl = "https://matrix.neutrino.su";
      report_stats = true;
      enable_metrics = true;

      enable_registration = true;
      registration_requires_token = true;

      # media_store_path = "/tank/matrix-media";
      dynamic_thumbnails = true;

      app_service_config_files = [
        "/var/lib/matrix-synapse/telegram-registration.yaml"
        "/var/lib/matrix-synapse/discord-registration.yaml"
      ];
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "::1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
      ];

      log_config = (pkgs.formats.yaml { }).generate "synapse-log.yaml" {
        version = 1;
        formatters.journal_fmt.format = "%(name)s: [%(request)s] %(message)s";
        handlers.journal = {
          class = "systemd.journal.JournalHandler";
          formatter = "journal_fmt";
          SYSLOG_IDENTIFIER = "synapse";
        };
        root = {
          level = "WARN";
          handlers = [ "journal" ];
        };
        disable_existing_loggers = true;
      };
    };
  };

  # systemd.tmpfiles.rules = ["d /tank/matrix-media 0750 matrix-synapse matrix-synapse - -"];

  systemd.services.matrix-synapse = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    # serviceConfig.ReadWritePaths = ["/tank/matrix-media"];
  };

  # Sliding sync
  # age.secrets.matrix-sliding-sync.file = ../../secrets/creds/matrix-sliding-sync.age;
  # services.matrix-sliding-sync = {
  #   enable = true;
  #   environmentFile = config.age.secrets.matrix-sliding-sync.path;
  #   settings = {
  #     SYNCV3_SERVER = "https://matrix.neutrino.su";
  #   };
  # };

  # Telegram bridge
  age.secrets.mautrix-telegram = {
    file = ../../secrets/creds/mautrix-telegram.age;
    owner = "mautrix-telegram";
    group = "mautrix-telegram";
  };

  services.mautrix-telegram = {
    enable = false;
    environmentFile = config.age.secrets.mautrix-telegram.path;
    settings = {
      homeserver = {
        address = "http://[::1]:8008";
        domain = "neutrino.su";
      };
      appservice = {
        address = "http://127.0.0.1:8194";
        hostname = "0.0.0.0";
        port = 8194;

        provisioning.enabled = false;

        id = "telegram";
        bot_username = "telegram";

        public = {
          enabled = true;
          prefix = "/public";
          external = "https://matrix.neutrino.su/telegram";
        };

        database = "postgresql:///mautrix-telegram?host=/run/postgresql";
      };
      bridge = {
        username_template = "tg_{userid}";
        alias_template = "tg_{groupname}";
        displayname_template = "[TG] {displayname}";

        allow_avatar_remove = false;
        allow_contact_info = false;

        startup_sync = true;

        public_portals = true;

        relaybot.authless_portals = false;
        permissions = {
          "neutrino.su" = "puppeting";
          "@averyanalex:neutrino.su" = "admin";
          "*" = "relaybot";
        };

        animated_sticker = {
          target = "webp";
          args = {
            width = 256;
            height = 256;
            fps = 30;
            background = "020202";
          };
        };
        animated_emoji = {
          target = "webp";
          args = {
            width = 64;
            height = 64;
            fps = 30;
          };
        };

        encryption = {
          allow = true;
          allow_key_sharing = true;
        };
      };
    };
  };

  users.users.mautrix-telegram = {
    isSystemUser = true;
    description = "Mautrix Telegram";
    group = "mautrix-telegram";
    uid = 641;
  };
  users.groups.mautrix-telegram.gid = 641;

  systemd.services.mautrix-telegram = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "mautrix-telegram";
    };
  };

  systemd.services.mautrix-telegram.path = with pkgs; [
    lottieconverter
    ffmpeg
  ];

  # Discord bridge
  age.secrets.matrix-appservice-discord.file = ../../secrets/creds/matrix-appservice-discord.age;

  services.matrix-appservice-discord = {
    # enable = true;
    environmentFile = config.age.secrets.matrix-appservice-discord.path;
    settings = {
      bridge = {
        domain = "neutrino.su";
        homeserverUrl = "https://matrix.neutrino.su";
        enableSelfServiceBridging = true;
        adminMxid = "@averyanalex:neutrino.su";
      };
      auth.usePrivilegedIntents = true;
      database = {
        filename = "";
        connString = "postgresql:///matrix-appservice-discord?host=/run/postgresql";
      };
      ghosts.usernamePattern = ":id";
    };
  };

  # users.users.matrix-appservice-discord = {
  #   isSystemUser = true;
  #   description = "Matrix Appservice Discord";
  #   group = "matrix-appservice-discord";
  #   uid = 678;
  # };
  # users.groups.matrix-appservice-discord.gid = 678;

  # systemd.services.matrix-appservice-discord = {
  #   requires = ["postgresql.service"];
  #   after = ["postgresql.service"];
  #   serviceConfig = {
  #     DynamicUser = lib.mkForce false;
  #     User = "matrix-appservice-discord";
  #   };
  # };

  persist.state.dirs = [
    {
      directory = "/var/lib/matrix-synapse";
      mode = "u=rwx,g=rx,o=";
      user = "matrix-synapse";
      group = "matrix-synapse";
    }
    {
      directory = "/var/lib/mautrix-telegram";
      mode = "u=rwx,g=rx,o=";
      user = "mautrix-telegram";
      group = "mautrix-telegram";
    }
    {
      directory = "/var/lib/matrix-appservice-discord";
      mode = "u=rwx,g=rx,o=";
      user = "matrix-appservice-discord";
      group = "matrix-appservice-discord";
    }
  ];

  services.postgresql = {
    ensureUsers = [
      {
        name = "matrix-synapse";
      }
      {
        name = "mautrix-telegram";
      }
      {
        name = "matrix-appservice-discord";
      }
    ];
  };
}
