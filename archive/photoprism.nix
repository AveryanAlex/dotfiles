{
  config,
  pkgs,
  ...
}:
let
  dockerImage = pkgs.dockerTools.pullImage {
    imageName = "photoprism/photoprism";
    finalImageTag = "latest";
    imageDigest = "sha256:b0d73530fd95c6e1f88b5b077a8690070a1eab7d33b8b8ea6b8410831dbc2f55";
    sha256 = "sha256-/AeOc954nX//Y/tI+eyk+SJktUkH/zfNuqyGtQlrlsg=";
  };
in
{
  age.secrets.photoprism.file = ../../secrets/intpass/photoprism.age;

  systemd.services."podman-photoprism" = {
    requires = [ "mysql.service" ];
    after = [ "mysql.service" ];
  };

  fileSystems."/var/lib/photoprism" = {
    device = "UUID=bcfa404a-68de-4a25-9fb0-4e972c8f9423";
    fsType = "btrfs";
    options = [
      "compress=zstd:7"
      "noatime"
      "subvol=@photoprism"
    ];
  };

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 2342 ];

  virtualisation.oci-containers = {
    containers = {
      photoprism = {
        image = "photoprism/photoprism";
        imageFile = dockerImage;
        volumes = [
          "/home/alex/tank/Галерея:/photoprism/originals"
          "/home/alex/tank/Import/PhotoPrism:/photoprism/import"
          "/var/lib/photoprism:/photoprism/storage"
        ];
        extraOptions = [ "--network=host" ];
        environment = {
          PHOTOPRISM_ADMIN_USER = "admin";
          PHOTOPRISM_AUTH_MODE = "password";
          PHOTOPRISM_SITE_URL = "https://prism.averyan.ru/";
          PHOTOPRISM_ORIGINALS_LIMIT = "6000";
          PHOTOPRISM_HTTP_COMPRESSION = "none";
          PHOTOPRISM_LOG_LEVEL = "info";
          PHOTOPRISM_READONLY = "false";
          PHOTOPRISM_EXPERIMENTAL = "false";
          PHOTOPRISM_DISABLE_CHOWN = "true";
          PHOTOPRISM_DISABLE_WEBDAV = "false";
          PHOTOPRISM_DISABLE_SETTINGS = "false";
          PHOTOPRISM_DISABLE_TENSORFLOW = "false";
          PHOTOPRISM_DISABLE_FACES = "false";
          PHOTOPRISM_DISABLE_CLASSIFICATION = "false";
          PHOTOPRISM_DISABLE_RAW = "false";
          PHOTOPRISM_RAW_PRESETS = "true";
          PHOTOPRISM_JPEG_QUALITY = "85";
          PHOTOPRISM_DETECT_NSFW = "true";
          PHOTOPRISM_UPLOAD_NSFW = "true";
          PHOTOPRISM_DATABASE_DRIVER = "mysql";
          PHOTOPRISM_DATABASE_SERVER = "127.0.0.1:3306";
          PHOTOPRISM_DATABASE_NAME = "photoprism";
          PHOTOPRISM_DATABASE_USER = "photoprism";
          PHOTOPRISM_SITE_CAPTION = "AI-Powered Photos App";
          PHOTOPRISM_SITE_DESCRIPTION = "";
          PHOTOPRISM_SITE_AUTHOR = "";
          ## Run/install on first startup (options: update https gpu tensorflow davfs clitools clean):
          # PHOTOPRISM_INIT: "https gpu tensorflow"
          ## Hardware Video Transcoding:
          PHOTOPRISM_FFMPEG_ENCODER = "software";
          # PHOTOPRISM_FFMPEG_BITRATE: "32"              # FFmpeg encoding bitrate limit in Mbit/s (default: 50)
          ## Run as a non-root user after initialization (supported: 0, 33, 50-99, 500-600, and 900-1200):
          PHOTOPRISM_UID = "1000";
          PHOTOPRISM_GID = "100";
          # PHOTOPRISM_UMASK: 0000
        };
        environmentFiles = [ config.age.secrets.photoprism.path ];
      };
    };
  };

  services.mysql = {
    ensureDatabases = [ "photoprism" ];
    ensureUsers = [
      {
        name = "photoprism";
        ensurePermissions = {
          "photoprism.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
