{ config, lib, ... }:
{
  imports = [ ../../modules/rustic-backup.nix ];

  age.secrets = {
    rustic-whale-s3.file = ../../secrets/creds/rustic-whale-s3.age;
  };

  services.rusticBackup = {
    enable = true;
    repositories.yandex = {
      repository = "opendal:s3";
      settings = {
        endpoint = "https://storage.yandexcloud.net";
        region = "ru-central1";
        bucket = "averylex-backups-whale";
        root = "/";
      };
      environmentFile = config.age.secrets.rustic-whale-s3.path;
      passwordFile = "/persist/rustic/repository-password";
    };
    defaults = {
      repository = "yandex";
      calendar = "*-*-* 04:00:00 Europe/Moscow";
      randomizedDelaySec = "15m";
    };
    # Declare jobs next to their services.
    jobs.tank = {
      paths = [ "/home/alex/tank" ];
      # The initial multi-terabyte upload can take several days.
      timeout = "7d";
      exclude = [
        # Covered by dedicated application jobs (or intentionally regenerable).
        "/home/alex/tank/Immich"
        "/home/alex/tank/nextcloud"
        "/home/alex/tank/Torrents"
        # Both nested filesystems are deliberately left out for now.
        "/home/alex/tank/hot"
        "/home/alex/tank/cold"
        # Do not traverse local snapshot history or back up trash/cache.
        "**/.snapshots"
        "/home/alex/tank/.Trash-1000"
        "/home/alex/tank/.mypy_cache"
      ];
    };
  };

  persist.cache.dirs = [
    {
      directory = "/var/cache/rustic-backup-yandex";
      mode = "0700";
    }
  ]
  ++ lib.mapAttrsToList (name: _: {
    directory = "/var/lib/rustic-backup-${name}";
    mode = "0700";
  }) (lib.filterAttrs (_: job: job.enable) config.services.rusticBackup.jobs);
}
