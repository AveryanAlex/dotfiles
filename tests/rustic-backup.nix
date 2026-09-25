# Evaluate without building a host: nix eval --json --file tests/rustic-backup.nix --arg pkgs 'import <nixpkgs> {}'
{ pkgs }:
let
  lib = pkgs.lib;
  evaluate =
    extra:
    (import "${pkgs.path}/nixos/lib/eval-config.nix" {
      system = "x86_64-linux";
      modules = [
        ../modules/rustic-backup.nix
        {
          nixpkgs.pkgs = pkgs;
          networking.hostName = "backup-test";
          system.stateVersion = "26.05";
          services.rusticBackup = {
            enable = true;
            repositories.local = {
              repository = "/tmp/rustic-module-test/repository";
              passwordFile = "/tmp/rustic-module-test/password";
            };
            defaults = {
              repository = "local";
              calendar = "weekly";
              memoryMax = "512M";
            };
            jobs = {
              files = {
                paths = [ "/tmp/rustic-module-test/source" ];
                exclude = [ "*.tmp" ];
              };
              dump = {
                calendar = null;
                backupStaging = true;
                prepareScript = "printf 'dump fixture' > \"$BACKUP_STAGING_DIR/database.sql\"";
                cleanupScript = "echo cleanup";
                requiresUnits = [ "postgresql.service" ];
              };
              disabled = {
                enable = false;
              };
            };
          };
        }
        extra
      ];
    }).config;
  cfg = evaluate { };
  overridden = evaluate { services.rusticBackup.jobs.files.calendar = lib.mkForce "daily"; };
  invalid = evaluate { services.rusticBackup.jobs.invalid.paths = [ "relative" ]; };
  checks = {
    inheritsSchedule = cfg.systemd.timers.rustic-backup-files.timerConfig.OnCalendar == "weekly";
    overridesSchedule = overridden.systemd.timers.rustic-backup-files.timerConfig.OnCalendar == "daily";
    inheritsLimits = cfg.systemd.services.rustic-backup-files.serviceConfig.MemoryMax == "512M";
    manualHasNoTimer = !(cfg.systemd.timers ? rustic-backup-dump);
    disabledHasNoService = !(cfg.systemd.services ? rustic-backup-disabled);
    sourcesRequireMounts =
      cfg.systemd.services.rustic-backup-files.unitConfig.RequiresMountsFor
      == [ "/tmp/rustic-module-test/source" ];
    dependencies = builtins.elem "postgresql.service" cfg.systemd.services.rustic-backup-dump.requires;
    credentials =
      cfg.systemd.services.rustic-backup-files.serviceConfig.LoadCredential
      == [ "repository-password:/tmp/rustic-module-test/password" ];
    invalidRejected = lib.any (
      a: !a.assertion && lib.hasPrefix "rusticBackup job invalid" a.message
    ) invalid.assertions;
  };
in
assert lib.all (x: x) (builtins.attrValues checks);
{
  inherit checks;
  profiles = {
    files = cfg.environment.etc."rustic/backup-job-files.toml".source;
    dump = cfg.environment.etc."rustic/backup-job-dump.toml".source;
    repository = cfg.environment.etc."rustic/backup-repository-local.toml".source;
  };
  # Allows shell checks without building any NixOS system.
  scripts = {
    files = cfg.systemd.services.rustic-backup-files.serviceConfig.ExecStart.text;
    dump = cfg.systemd.services.rustic-backup-dump.serviceConfig.ExecStart.text;
  };
  executables = {
    files = cfg.systemd.services.rustic-backup-files.serviceConfig.ExecStart;
    dump = cfg.systemd.services.rustic-backup-dump.serviceConfig.ExecStart;
  };
}
