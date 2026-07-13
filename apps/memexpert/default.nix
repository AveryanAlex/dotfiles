let
  name = "memexpert";
  subnet = "10.90.99";
  publicHost = "beta.memexpert.net";
  s3Host = "beta-s3.memexpert.net";

  mainImage = "ghcr.io/averyanalex/memexpert/main:main";
  workerImage = "ghcr.io/averyanalex/memexpert/worker:main";
  frontendImage = "ghcr.io/averyanalex/memexpert/frontend:main";

  s3AccessKey = name;
  s3Bucket = name;
  s3Region = "us-east-1";

  uidMaps = [ "0:100000:100000" ];
  gidMaps = [ "0:100000:100000" ];

  oneShotServiceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    Restart = "on-failure";
    RestartSec = "5s";
    TimeoutStartSec = 900;
  };
in
{
  config,
  secrets,
  ...
}:
let
  secretName = "${name}-app";
  secretFile = config.age.secrets.${secretName}.path;
  registryAuthEnvironment = [
    "REGISTRY_AUTH_FILE=${config.environment.sessionVariables.REGISTRY_AUTH_FILE}"
  ];

  commonAppEnvironment = {
    APP_HOST = "0.0.0.0";
    APP_PORT = "8000";
    REDIS_URL = "redis://${name}-redis:6379/0";
    QDRANT_URL = "http://${name}-qdrant:6333";
    MEILISEARCH_URL = "http://${name}-meilisearch:7700";
    S3_ENDPOINT = "https://${s3Host}";
    S3_ACCESS_KEY = s3AccessKey;
    S3_BUCKET = s3Bucket;
    S3_REGION = s3Region;
    IMGPROXY_BASE_URL = "http://${name}-imgproxy:8080";
    IMGPROXY_PUBLIC_BASE_URL = "https://${publicHost}/img";
    MEDIA_PUBLIC_BASE_URL = "https://${publicHost}/api/v1/media/files";
    PIPELINE_ALLOWED_MIME_TYPES = "image/jpeg,image/png,image/webp,image/gif,video/mp4,video/quicktime,video/webm";
    PIPELINE_BROKER_CONNECTION_TIMEOUT_SECONDS = "10.0";
    PIPELINE_STORAGE_CONNECTION_TIMEOUT_SECONDS = "10.0";
    PIPELINE_VOYAGE_PROVIDER_MODE = "live";
    PIPELINE_VOYAGE_MODEL = "voyage-multimodal-3.5";
    PIPELINE_VOYAGE_OUTPUT_DIMENSIONS = "1024";
    PIPELINE_VOYAGE_API_URL = "https://api.voyageai.com/v1/multimodalembeddings";
    PIPELINE_CLASSIFICATION_PROVIDER_MODE = "fake";
    PIPELINE_FAKE_CLASSIFICATION_NSFW_SCORE = "0.0";
    PIPELINE_CLASSIFICATION_MODEL = "memexpert-nsfw-v1";
    PIPELINE_CLASSIFICATION_TIMEOUT_SECONDS = "15.0";
    PIPELINE_CLASSIFICATION_NSFW_THRESHOLD = "0.5";
    PIPELINE_SEO_PROVIDER_MODE = "static";
    PIPELINE_SEO_MODEL = "gpt-5-mini";
    PIPELINE_SEO_TIMEOUT_SECONDS = "30.0";
    PIPELINE_SEO_MAX_ATTEMPTS = "2";
    PIPELINE_SEO_IMAGE_MAX_BYTES = "5242880";
    PIPELINE_SEO_PROMPT_VERSION = "meme-seo-v1";
    AUTH_ACCESS_TOKEN_TTL_SECONDS = "2592000";
    AUTH_ACCESS_COOKIE_NAME = "memexpert_access_token";
    AUTH_ACCESS_COOKIE_SECURE = "true";
    AUTH_ACCESS_COOKIE_HTTPONLY = "true";
    AUTH_ACCESS_COOKIE_SAMESITE = "lax";
    AUTH_ACCESS_COOKIE_PATH = "/";
    AUTH_ACCESS_COOKIE_DOMAIN = publicHost;
    AUTH_TELEGRAM_LOGIN_MAX_AGE_SECONDS = "300";
    AUTH_TELEGRAM_MINIAPP_MAX_AGE_SECONDS = "300";
    AUTH_TELEGRAM_LINK_CODE_TTL_SECONDS = "600";
    AUTH_GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
    AUTH_GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo";
    AUTH_GOOGLE_TIMEOUT_SECONDS = "10.0";
    SECURITY_CORS_ALLOWED_ORIGINS = "https://${publicHost},https://web.telegram.org,https://oauth.telegram.org";
    SECURITY_CORS_ALLOWED_ORIGIN_REGEX = "^https://([a-z0-9-]+\\.)?memexpert\\.net$";
    SECURITY_CSRF_HEADER_NAME = "X-Requested-With";
    SECURITY_RATE_LIMIT_ENABLED = "true";
    SECURITY_RATE_LIMIT_FAIL_CLOSED = "true";
    SECURITY_RATE_LIMIT_REDIS_TIMEOUT_SECONDS = "0.5";
    SECURITY_RATE_LIMIT_AUTH_WRITE_MAX_REQUESTS = "10";
    SECURITY_RATE_LIMIT_AUTH_WRITE_WINDOW_SECONDS = "60";
    SECURITY_RATE_LIMIT_SEARCH_FEED_MAX_REQUESTS = "30";
    SECURITY_RATE_LIMIT_SEARCH_FEED_WINDOW_SECONDS = "60";
    SECURITY_RATE_LIMIT_WRITE_MAX_REQUESTS = "60";
    SECURITY_RATE_LIMIT_WRITE_WINDOW_SECONDS = "60";
    SECURITY_RATE_LIMIT_UPLOAD_MAX_REQUESTS = "10";
    SECURITY_RATE_LIMIT_UPLOAD_WINDOW_SECONDS = "60";
    SECURITY_RATE_LIMIT_ADMIN_MAX_REQUESTS = "120";
    SECURITY_RATE_LIMIT_ADMIN_WINDOW_SECONDS = "60";
    SCHEDULER_MATERIALIZED_VIEW_REFRESH_ENABLED = "true";
    SCHEDULER_MATERIALIZED_VIEW_REFRESH_INTERVAL_SECONDS = "300";
    SCHEDULER_SOURCE_ENGAGEMENT_CAPTURE_ENABLED = "true";
    SCHEDULER_SOURCE_ENGAGEMENT_CAPTURE_INTERVAL_SECONDS = "21600";
    SCHEDULER_SOURCE_ENGAGEMENT_CAPTURE_BATCH_SIZE = "100";
    SCHEDULER_SOURCE_ENGAGEMENT_CAPTURE_PER_SESSION_BATCH_SIZE = "20";
    SCHEDULER_SOURCE_ENGAGEMENT_CAPTURE_LEASE_TIMEOUT_SECONDS = "1800";
    SCHEDULER_MOTD_ENABLED = "true";
    SCHEDULER_MOTD_INTERVAL_SECONDS = "86400";
    MOTD_ALGORITHM_VERSION = "motd_v1";
    MOTD_CANDIDATE_LOOKBACK_DAYS = "30";
    MOTD_CANDIDATE_LIMIT = "50";
    MOTD_MIN_QUALITY_SCORE = "0.5";
    MOTD_POPULARITY_WEIGHT = "0.35";
    MOTD_TRENDING_GROWTH_WEIGHT = "0.30";
    MOTD_NOVELTY_WEIGHT = "0.20";
    MOTD_QUALITY_WEIGHT = "0.15";
    SCHEDULER_SEARCH_INDEX_SYNC_ENABLED = "true";
    SCHEDULER_SEARCH_INDEX_SYNC_INTERVAL_SECONDS = "600";
    SCHEDULER_SEARCH_INDEX_SYNC_BATCH_SIZE = "50";
    SCHEDULER_SEARCH_INDEX_SYNC_PROCESSING_TIMEOUT_SECONDS = "900";
    SCHEDULER_SEO_BACKLOG_BATCHES_ENABLED = "false";
    SCHEDULER_SEO_BACKLOG_BATCHES_INTERVAL_SECONDS = "900";
    SCHEDULER_SEO_BACKLOG_BATCH_SIZE = "25";
    SCHEDULER_RABBITMQ_OUTBOX_PUBLISHER_ENABLED = "true";
    SCHEDULER_RABBITMQ_OUTBOX_PUBLISHER_INTERVAL_SECONDS = "5";
    SCHEDULER_RABBITMQ_OUTBOX_PUBLISHER_BATCH_SIZE = "100";
    SCHEDULER_RABBITMQ_OUTBOX_PUBLISHER_STALE_TIMEOUT_SECONDS = "300";
    SCHEDULER_ADVISORY_LOCK_ENABLED = "true";
    SCHEDULER_ADVISORY_LOCK_KEY = "0,0";
  };

  workerEnvironment = commonAppEnvironment // {
    PIPELINE_TRANSCODE_TIMEOUT_SECONDS = "180.0";
    PIPELINE_OCR_PROVIDER_MODE = "live";
    PIPELINE_OCR_PRIMARY_ENGINE = "paddleocr";
    PIPELINE_OCR_PADDLE_COMMAND = "/opt/paddleocr-venv/bin/python /app/scripts/paddleocr_json.py --input {input}";
    PIPELINE_OCR_TIMEOUT_SECONDS = "120.0";
    PIPELINE_OCR_LOW_CONFIDENCE_THRESHOLD = "0.6";
  };
in
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/db 700 100999 100999 - -"
    "d /persist/${name}/redis 700 100999 100999 - -"
    "d /persist/${name}/rabbitmq 700 100999 100999 - -"
    "d /persist/${name}/qdrant 700 100999 100999 - -"
    "d /persist/${name}/meilisearch 700 101000 101000 - -"
    "d /persist/${name}/minio 700 100999 100999 - -"
  ];

  # Keep the beta container stack separate from the native memexpert.net service.
  # This file should contain only secret values that are not declared below, including
  # DATABASE_URL, RABBITMQ_URL, MEILISEARCH_MASTER_KEY, MEILI_MASTER_KEY,
  # S3_SECRET_KEY, MINIO_ROOT_PASSWORD, AWS_SECRET_ACCESS_KEY, IMGPROXY_KEY,
  # IMGPROXY_SALT, AUTH_JWT_SECRET, and provider/API credentials.
  age.secrets.${secretName}.file = "${secrets}/apps/memexpert.age";

  networking.tproxy.forward."pme-${name}" = { };

  services.nginx.virtualHosts = {
    ${publicHost} = {
      useACMEHost = "memexpert.net";
      forceSSL = true;

      locations."/api/v1/" = {
        proxyPass = "http://${subnet}.10:8000/api/v1/";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 200M;
          proxy_request_buffering off;
        '';
      };

      locations."/img/" = {
        proxyPass = "http://${subnet}.9:8080/";
        proxyWebsockets = true;
      };

      locations."/" = {
        proxyPass = "http://${subnet}.2:3000";
        proxyWebsockets = true;
      };
    };

    ${s3Host} = {
      useACMEHost = "memexpert.net";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${subnet}.8:9000";
        extraConfig = ''
          client_max_body_size 200M;
          proxy_buffering off;
          proxy_request_buffering off;
        '';
      };
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
      network = networks.${name}.ref;
    in
    {
      networks.${name}.networkConfig = {
        subnets = [ "${subnet}.0/24" ];
        podmanArgs = [ "--interface-name=pme-${name}" ];
      };

      containers = {
        "${name}-db" = {
          containerConfig = {
            image = "docker.io/library/postgres:16";
            autoUpdate = "registry";
            memory = "4g";
            networks = [ network ];
            ip = "${subnet}.3";
            volumes = [ "/persist/${name}/db:/var/lib/postgresql/data" ];
            environments = {
              POSTGRES_DB = name;
              POSTGRES_USER = name;
            };
            environmentFiles = [ secretFile ];
            inherit uidMaps gidMaps;
          };
        };

        "${name}-redis" = {
          containerConfig = {
            image = "docker.io/library/redis:7";
            autoUpdate = "registry";
            memory = "1g";
            networks = [ network ];
            ip = "${subnet}.4";
            volumes = [ "/persist/${name}/redis:/data" ];
            exec = [
              "redis-server"
              "--appendonly"
              "yes"
            ];
            inherit uidMaps gidMaps;
          };
        };

        "${name}-rabbitmq" = {
          containerConfig = {
            image = "docker.io/library/rabbitmq:4-management";
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.5";
            volumes = [ "/persist/${name}/rabbitmq:/var/lib/rabbitmq" ];
            environments.RABBITMQ_DEFAULT_USER = name;
            environmentFiles = [ secretFile ];
            inherit uidMaps gidMaps;
          };
        };

        "${name}-qdrant" = {
          containerConfig = {
            image = "docker.io/qdrant/qdrant:latest";
            autoUpdate = "registry";
            memory = "4g";
            networks = [ network ];
            ip = "${subnet}.6";
            volumes = [ "/persist/${name}/qdrant:/qdrant/storage" ];
            inherit uidMaps gidMaps;
          };
        };

        "${name}-meilisearch" = {
          containerConfig = {
            # Pin until Meilisearch data is migrated explicitly; 1.48.x cannot read 1.47.0 data.
            image = "docker.io/getmeili/meilisearch:v1.47.0";
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.7";
            volumes = [ "/persist/${name}/meilisearch:/meili_data" ];
            environments = {
              MEILI_ENV = "production";
              MEILI_NO_ANALYTICS = "true";
            };
            environmentFiles = [ secretFile ];
            inherit uidMaps gidMaps;
          };
        };

        "${name}-minio" = {
          containerConfig = {
            image = "docker.io/minio/minio:latest";
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.8";
            volumes = [ "/persist/${name}/minio:/data" ];
            environments = {
              MINIO_ROOT_USER = s3AccessKey;
              MINIO_SERVER_URL = "https://${s3Host}";
            };
            environmentFiles = [ secretFile ];
            exec = [
              "server"
              "/data"
              "--console-address"
              ":9001"
            ];
            inherit uidMaps gidMaps;
          };
        };

        "${name}-minio-init" = {
          containerConfig = {
            image = "docker.io/minio/mc:latest";
            autoUpdate = "registry";
            memory = "512m";
            networks = [ network ];
            ip = "${subnet}.14";
            environments = {
              MINIO_ROOT_USER = s3AccessKey;
              S3_BUCKET = s3Bucket;
            };
            environmentFiles = [ secretFile ];
            entrypoint = "/bin/sh";
            exec = [
              "-c"
              ''mc alias set ${name} http://${name}-minio:9000 "$''${MINIO_ROOT_USER}" "$''${MINIO_ROOT_PASSWORD}" && mc mb --ignore-existing "${name}/$''${S3_BUCKET}"''
            ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-minio.service" ];
            After = Requires;
          };
          serviceConfig = oneShotServiceConfig;
        };

        "${name}-imgproxy" = {
          containerConfig = {
            image = "docker.io/darthsim/imgproxy:latest";
            autoUpdate = "registry";
            memory = "1g";
            networks = [ network ];
            ip = "${subnet}.9";
            environments = {
              IMGPROXY_USE_S3 = "true";
              IMGPROXY_S3_ENDPOINT = "http://${name}-minio:9000";
              IMGPROXY_S3_REGION = s3Region;
              IMGPROXY_S3_USE_PATH_STYLE = "true";
              AWS_ACCESS_KEY_ID = s3AccessKey;
              IMGPROXY_BIND = ":8080";
            };
            environmentFiles = [ secretFile ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-minio.service" ];
            After = Requires;
          };
        };

        "${name}-migrate" = {
          containerConfig = {
            image = mainImage;
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.15";
            environments = commonAppEnvironment;
            environmentFiles = [ secretFile ];
            exec = [
              "alembic"
              "upgrade"
              "head"
            ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [
              "${name}-db.service"
              "${name}-redis.service"
              "${name}-rabbitmq.service"
              "${name}-qdrant.service"
              "${name}-meilisearch.service"
              "${name}-minio-init.service"
              "${name}-imgproxy.service"
            ];
            After = Requires;
          };
          serviceConfig = oneShotServiceConfig // {
            Environment = registryAuthEnvironment;
          };
        };

        "${name}-api" = {
          containerConfig = {
            image = mainImage;
            autoUpdate = "registry";
            memory = "6g";
            networks = [ network ];
            ip = "${subnet}.10";
            environments = commonAppEnvironment;
            environmentFiles = [ secretFile ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-migrate.service" ];
            After = Requires;
          };
          serviceConfig.Environment = registryAuthEnvironment;
        };

        "${name}-workers" = {
          containerConfig = {
            image = workerImage;
            autoUpdate = "registry";
            memory = "8g";
            networks = [ network ];
            ip = "${subnet}.11";
            environments = workerEnvironment;
            environmentFiles = [ secretFile ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [
              "${name}-migrate.service"
              "${name}-rabbitmq.service"
            ];
            After = Requires;
          };
          serviceConfig.Environment = registryAuthEnvironment;
        };

        "${name}-telegram-crawler" = {
          containerConfig = {
            image = workerImage;
            autoUpdate = "registry";
            memory = "4g";
            networks = [ network ];
            ip = "${subnet}.12";
            environments = workerEnvironment;
            environmentFiles = [ secretFile ];
            exec = [ "memexpert-telegram-crawler" ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-migrate.service" ];
            After = Requires;
          };
          serviceConfig.Environment = registryAuthEnvironment;
        };

        "${name}-scheduler" = {
          containerConfig = {
            image = mainImage;
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.13";
            environments = commonAppEnvironment;
            environmentFiles = [ secretFile ];
            exec = [ "memexpert-scheduler" ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-migrate.service" ];
            After = Requires;
          };
          serviceConfig.Environment = registryAuthEnvironment;
        };

        "${name}-frontend" = {
          containerConfig = {
            image = frontendImage;
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.2";
            environments = {
              HOST = "0.0.0.0";
              PORT = "3000";
              ORIGIN = "https://${publicHost}";
              FRONTEND_ORIGIN = "https://${publicHost}";
              API_BASE_URL = "http://${name}-api:8000";
            };
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-api.service" ];
            After = Requires;
          };
          serviceConfig.Environment = registryAuthEnvironment;
        };

        "${name}-bot" = {
          containerConfig = {
            image = mainImage;
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.16";
            environments = commonAppEnvironment;
            environmentFiles = [ secretFile ];
            exec = [ "memexpert-bot" ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-migrate.service" ];
            After = Requires;
          };
          serviceConfig.Environment = registryAuthEnvironment;
        };
      };
    };
}
