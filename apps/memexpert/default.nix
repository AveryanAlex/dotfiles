let
  name = "memexpert";
  subnet = "10.90.99";
  publicHost = "beta.memexpert.net";
  s3Host = "beta-s3.memexpert.net";

  mainImage = "ghcr.io/averyanalex/memexpert/main:main";
  workerImage = "ghcr.io/averyanalex/memexpert/worker:main";
  frontendImage = "ghcr.io/averyanalex/memexpert/frontend:main";
  workerStopTimeoutSeconds = 240;

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
    DATABASE_CONNECT_TIMEOUT_SECONDS = "5.0";
    DATABASE_POOL_SIZE = "4";
    DATABASE_MAX_OVERFLOW = "2";
    DATABASE_POOL_TIMEOUT_SECONDS = "5.0";
    DATABASE_APPLICATION_NAME = name;
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
    PIPELINE_CAPACITY_CLOSE_PENDING_COUNT = "1000";
    PIPELINE_CAPACITY_REOPEN_PENDING_COUNT = "500";
    PIPELINE_CAPACITY_CLOSE_OLDEST_AGE_SECONDS = "3600";
    PIPELINE_CAPACITY_REOPEN_OLDEST_AGE_SECONDS = "900";
    PIPELINE_CIRCUIT_FAILURE_THRESHOLD = "3";
    PIPELINE_CIRCUIT_COOLDOWN_SECONDS = "30";
    PIPELINE_STUCK_RECLAIM_AFTER_SECONDS = "900";
    RECOVERY_TELEGRAM_POLL_INTERVAL_SECONDS = "5";
    RECOVERY_TELEGRAM_BATCH_SIZE = "10";
    PIPELINE_STORAGE_CONNECTION_TIMEOUT_SECONDS = "10.0";
    RUNTIME_HEALTH_FILE = "/tmp/memexpert-runtime-health.json";
    RUNTIME_HEALTH_INTERVAL_SECONDS = "10.0";
    RUNTIME_HEALTH_STALE_AFTER_SECONDS = "45.0";
    RUNTIME_HEALTH_OPERATION_TIMEOUT_SECONDS = "900.0";
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
    SCHEDULER_RECOVERY_DISPATCH_ENABLED = "true";
    SCHEDULER_RECOVERY_DISPATCH_INTERVAL_SECONDS = "5";
    SCHEDULER_RECOVERY_DISPATCH_BATCH_SIZE = "50";
    SCHEDULER_PIPELINE_CAPACITY_REFRESH_ENABLED = "true";
    SCHEDULER_PIPELINE_CAPACITY_REFRESH_INTERVAL_SECONDS = "15";
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

  workerRoles = {
    media = {
      ip = "${subnet}.11";
      prefetch = 1;
      poolSize = 2;
      maxOverflow = 1;
      memory = "4g";
      cpuQuota = "400%";
      pidsLimit = 256;
      startupRetries = 8;
    };
    ocr = {
      ip = "${subnet}.17";
      # Run two isolated Paddle helpers with up to eight CPU threads each.
      prefetch = 2;
      poolSize = 2;
      maxOverflow = 1;
      memory = "8g";
      cpuQuota = "1600%";
      pidsLimit = 384;
      startupRetries = 20;
      extraEnvironment = {
        PIPELINE_OCR_PADDLE_COMMAND = "/opt/paddleocr-venv/bin/python /app/scripts/paddleocr_json.py --input {input} --cpu-threads 8";
        OMP_NUM_THREADS = "8";
        OPENBLAS_NUM_THREADS = "8";
        MKL_NUM_THREADS = "8";
        NUMEXPR_NUM_THREADS = "8";
      };
    };
    enrichment = {
      ip = "${subnet}.18";
      prefetch = 2;
      poolSize = 3;
      maxOverflow = 1;
      memory = "4g";
      cpuQuota = "400%";
      pidsLimit = 192;
      startupRetries = 8;
    };
    sync = {
      ip = "${subnet}.19";
      prefetch = 4;
      poolSize = 3;
      maxOverflow = 1;
      memory = "2g";
      cpuQuota = "200%";
      pidsLimit = 128;
      startupRetries = 8;
    };
    telegram = {
      ip = "${subnet}.20";
      prefetch = 1;
      poolSize = 2;
      maxOverflow = 1;
      memory = "2g";
      cpuQuota = "200%";
      pidsLimit = 128;
      startupRetries = 8;
    };
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
      runtimeHealthConfig = {
        healthCmd = "memexpert-runtime-health";
        healthInterval = "15s";
        healthTimeout = "5s";
        healthRetries = 3;
        healthOnFailure = "kill";
        healthStartupCmd = "memexpert-runtime-health";
        healthStartupInterval = "15s";
        healthStartupTimeout = "5s";
        healthStartupSuccess = 1;
        notify = "healthy";
      };
      mkWorker = role: roleConfig: {
        containerConfig = runtimeHealthConfig // {
          image = workerImage;
          autoUpdate = "registry";
          memory = roleConfig.memory;
          stopTimeout = workerStopTimeoutSeconds;
          networks = [ network ];
          ip = roleConfig.ip;
          pidsLimit = roleConfig.pidsLimit;
          environments =
            workerEnvironment
            // (roleConfig.extraEnvironment or { })
            // {
              PIPELINE_WORKER_PREFETCH_COUNT = toString roleConfig.prefetch;
              DATABASE_POOL_SIZE = toString roleConfig.poolSize;
              DATABASE_MAX_OVERFLOW = toString roleConfig.maxOverflow;
              DATABASE_POOL_TIMEOUT_SECONDS = "5.0";
              DATABASE_APPLICATION_NAME = "${name}-worker-${role}";
            };
          environmentFiles = [ secretFile ];
          exec = [
            "memexpert-workers"
            "--role"
            role
          ];
          healthStartupRetries = roleConfig.startupRetries;
          inherit uidMaps gidMaps;
        };
        unitConfig = rec {
          Requires = [
            "${name}-migrate.service"
            "${name}-rabbitmq.service"
          ];
          After = Requires;
          Conflicts = [ "${name}-workers.service" ];
          StartLimitIntervalSec = "10min";
          StartLimitBurst = 6;
        };
        serviceConfig = {
          Environment = registryAuthEnvironment;
          RestartSec = "10s";
          TimeoutStopSec = "${toString (workerStopTimeoutSeconds + 30)}s";
          MemorySwapMax = 0;
          CPUQuota = roleConfig.cpuQuota;
        };
      };
      workerContainers = builtins.listToAttrs (
        builtins.map (role: {
          name = "${name}-worker-${role}";
          value = mkWorker role workerRoles.${role};
        }) (builtins.attrNames workerRoles)
      );
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
            environments = commonAppEnvironment // {
              DATABASE_APPLICATION_NAME = "${name}-migrate";
            };
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
            # Reploy restarts the long-running app units, not this removed
            # one-shot container. Leave migrations inactive after success so
            # Requires= pulls a fresh migration run into every app restart
            # transaction before any new image starts.
            RemainAfterExit = false;
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
            environments = commonAppEnvironment // {
              DATABASE_APPLICATION_NAME = "${name}-api";
            };
            environmentFiles = [ secretFile ];
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-migrate.service" ];
            After = Requires;
          };
          serviceConfig.Environment = registryAuthEnvironment;
        };

        "${name}-telegram-crawler" = {
          containerConfig = runtimeHealthConfig // {
            image = workerImage;
            autoUpdate = "registry";
            memory = "4g";
            networks = [ network ];
            ip = "${subnet}.12";
            environments = workerEnvironment // {
              DATABASE_APPLICATION_NAME = "${name}-telegram-crawler";
            };
            environmentFiles = [ secretFile ];
            exec = [ "memexpert-telegram-crawler" ];
            healthStartupRetries = 20;
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-migrate.service" ];
            After = Requires;
            StartLimitIntervalSec = "10min";
            StartLimitBurst = 6;
          };
          serviceConfig = {
            Environment = registryAuthEnvironment;
            RestartSec = "10s";
          };
        };

        "${name}-scheduler" = {
          containerConfig = runtimeHealthConfig // {
            image = mainImage;
            autoUpdate = "registry";
            memory = "2g";
            networks = [ network ];
            ip = "${subnet}.13";
            environments = commonAppEnvironment // {
              DATABASE_APPLICATION_NAME = "${name}-scheduler";
            };
            environmentFiles = [ secretFile ];
            exec = [ "memexpert-scheduler" ];
            healthStartupRetries = 8;
            inherit uidMaps gidMaps;
          };
          unitConfig = rec {
            Requires = [ "${name}-migrate.service" ];
            After = Requires;
            StartLimitIntervalSec = "10min";
            StartLimitBurst = 6;
          };
          serviceConfig = {
            Environment = registryAuthEnvironment;
            RestartSec = "10s";
          };
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
            environments = commonAppEnvironment // {
              DATABASE_APPLICATION_NAME = "${name}-bot";
            };
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
      }
      // workerContainers;
    };
}
