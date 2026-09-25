{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.rusticBackup;
  toml = pkgs.formats.toml { };
  namedType = types.strMatching "[a-zA-Z0-9][a-zA-Z0-9_-]*";
  commonOptions = {
    repository = mkOption {
      type = types.str;
      default = "yandex";
      description = "Named repository to use.";
    };
    calendar = mkOption {
      type = types.nullOr types.str;
      default = "daily";
      description = "systemd OnCalendar expression; null disables the timer.";
    };
    randomizedDelaySec = mkOption {
      type = types.str;
      default = "15m";
      description = "Timer jitter.";
    };
    persistent = mkOption {
      type = types.bool;
      default = true;
      description = "Catch up missed timer runs.";
    };
    timeout = mkOption {
      type = types.str;
      default = "12h";
      description = "Maximum job runtime, including waiting for job or maintenance locks.";
    };
    nice = mkOption {
      type = types.ints.between (-20) 19;
      default = 10;
      description = "CPU scheduling priority.";
    };
    memoryMax = mkOption {
      type = types.str;
      default = "2G";
      description = "Memory limit for the job and its hooks.";
    };
  };
  jobs = filterAttrs (_: job: job.enable) cfg.jobs;
  repoProfile = name: repo: {
    global.no-progress = true;
    repository = {
      repository = repo.repository;
      options = repo.settings;
      options-hot = repo.hotSettings;
      options-cold = repo.coldSettings;
      cache-dir = "/var/cache/rustic-backup-${name}";
    }
    // optionalAttrs (repo.hotRepository != null) { repo-hot = repo.hotRepository; };
  };
  credentials = name: repo: {
    LoadCredential = [ "repository-password:${repo.passwordFile}" ];
    EnvironmentFile = optional (repo.environmentFile != null) repo.environmentFile;
    CacheDirectory = "rustic-backup-${name}";
    CacheDirectoryMode = "0700";
    UMask = "0077";
  };
  lockScript = name: shared: ''
    exec 9>/run/lock/rustic-backup-${name}.lock
    flock ${optionalString shared "-s "}9
    export RUSTIC_PASSWORD_FILE="$CREDENTIALS_DIRECTORY/repository-password"
  '';
  hook =
    name: phase: job:
    pkgs.writeShellScript "rustic-${name}-${phase}" ''
      set -euo pipefail
      ${job.${phase + "Script"}}
    '';
  jobScript =
    name: job:
    pkgs.writeShellScript "rustic-backup-${name}" ''
      set -euo pipefail
      exec 8>/run/lock/rustic-job-${name}.lock
      flock 8
      ${lockScript job.repository true}
      export BACKUP_STAGING_DIR="/var/lib/rustic-backup-${name}/staging"
      # This fixed, private path gives snapshots stable source paths.
      rm -rf -- "$BACKUP_STAGING_DIR"
      mkdir -p -- "$BACKUP_STAGING_DIR"
      cleanup() {
        status=$?
        trap - EXIT
        set +e
        ${hook name "cleanup" job}
        cleanup_status=$?
        rm -rf -- "$BACKUP_STAGING_DIR"
        if [ "$status" -eq 0 ]; then status=$cleanup_status; fi
        exit "$status"
      }
      trap cleanup EXIT
      trap 'exit 143' TERM
      trap 'exit 130' INT
      ${hook name "prepare" job}
      ${getExe cfg.package} -P /etc/rustic/backup-job-${name}.toml backup
      ${hook name "success" job}
    '';
  adminCommand =
    name: repo:
    pkgs.writeShellApplication {
      name = "rustic-backup-${name}";
      runtimeInputs = [ pkgs.systemd ];
      text = ''
        if [ "$EUID" -ne 0 ]; then
          echo "Run this command with sudo." >&2
          exit 1
        fi
        exec systemd-run --quiet --wait --pipe --collect --service-type=exec \
          --property=${escapeShellArg "LoadCredential=repository-password:${repo.passwordFile}"} \
          ${
            optionalString (
              repo.environmentFile != null
            ) "--property=${escapeShellArg "EnvironmentFile=${repo.environmentFile}"}"
          } \
          --property=CacheDirectory=rustic-backup-${name} \
          --property=CacheDirectoryMode=0700 --property=UMask=0077 \
          ${pkgs.writeShellScript "rustic-admin-${name}" ''
            set -euo pipefail
            export PATH=${makeBinPath [ pkgs.util-linux ]}:"$PATH"
            ${lockScript name false}
            exec ${getExe cfg.package} -P /etc/rustic/backup-repository-${name}.toml "$@"
          ''} "$@"
      '';
    };
in
{
  options.services.rusticBackup = {
    enable = mkEnableOption "declarative rustic backup jobs";
    package = mkPackageOption pkgs "rustic" { };
    defaults = mkOption {
      type = types.submodule { options = commonOptions; };
      default = { };
      description = "Defaults inherited by jobs; individual job options take precedence.";
    };
    repositories = mkOption {
      default = { };
      description = "Repositories shared by concurrent jobs. The admin helper takes an exclusive maintenance lock.";
      type = types.attrsOf (
        types.submodule {
          options = {
            repository = mkOption {
              type = types.str;
              description = "Rustic repository URL.";
            };
            hotRepository = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Optional hot metadata repository URL.";
            };
            settings = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Shared backend options; never put secrets here.";
            };
            hotSettings = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Hot backend options.";
            };
            coldSettings = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Cold backend options.";
            };
            environmentFile = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Runtime systemd EnvironmentFile holding backend credentials.";
            };
            passwordFile = mkOption {
              type = types.str;
              description = "Runtime password file, passed with systemd LoadCredential.";
            };
          };
        }
      );
    };
    jobs = mkOption {
      default = { };
      description = "Backup jobs, normally declared alongside their owning service.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }: {
            options = commonOptions // {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable this job.";
              };
              paths = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Absolute source directories or files.";
              };
              exclude = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Rustic/gitignore exclusion patterns (without inversion).";
              };
              tags = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Additional snapshot tags.";
              };
              runtimePackages = mkOption {
                type = types.listOf types.package;
                default = [ ];
                description = "Tools available to all hooks.";
              };
              requiresUnits = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Units required and ordered before this job.";
              };
              requiresMountsFor = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Additional paths whose mounts must be available; source paths are included automatically.";
              };
              prepareScript = mkOption {
                type = types.lines;
                default = "";
                description = "Runs before backup. Failure aborts the job.";
              };
              successScript = mkOption {
                type = types.lines;
                default = "";
                description = "Runs only after a successful backup.";
              };
              cleanupScript = mkOption {
                type = types.lines;
                default = "";
                description = "Runs after preparation/backup, also on failure or TERM. Must be idempotent; SIGKILL/power loss cannot run hooks.";
              };
              backupStaging = mkOption {
                type = types.bool;
                default = false;
                description = "Include the per-run BACKUP_STAGING_DIR in the snapshot.";
              };
              extraSettings = mkOption {
                type = toml.type;
                default = { };
                description = "Additional [backup] options. Module-owned source, host, label, tags and exclusions take precedence.";
              };
            };
            config = mapAttrs (key: _: mkDefault cfg.defaults.${key}) commonOptions;
          }
        )
      );
    };
  };

  config = mkIf cfg.enable {
    assertions =
      (mapAttrsToList (name: _: {
        assertion = namedType.check name;
        message = "rusticBackup repository name must match [a-zA-Z0-9][a-zA-Z0-9_-]*: ${name}";
      }) cfg.repositories)
      ++ (mapAttrsToList (name: job: {
        assertion =
          namedType.check name
          && builtins.hasAttr job.repository cfg.repositories
          && (job.paths != [ ] || job.backupStaging)
          && all (hasPrefix "/") (job.paths ++ job.requiresMountsFor);
        message = "rusticBackup job ${name}: use a safe name, an existing repository and absolute source paths (or backupStaging).";
      }) jobs);

    environment.systemPackages = [ cfg.package ] ++ mapAttrsToList adminCommand cfg.repositories;
    environment.etc =
      (mapAttrs' (
        name: repo:
        nameValuePair "rustic/backup-repository-${name}.toml" {
          source = toml.generate "rustic-repository-${name}.toml" (repoProfile name repo);
        }
      ) cfg.repositories)
      // (mapAttrs' (
        name: job:
        nameValuePair "rustic/backup-job-${name}.toml" {
          source = toml.generate "rustic-job-${name}.toml" (
            (repoProfile job.repository cfg.repositories.${job.repository})
            // {
              backup = job.extraSettings // {
                host = config.networking.hostName;
                label = name;
                tags = [ "job:${name}" ] ++ job.tags;
                globs = map (pattern: "!${pattern}") job.exclude;
                snapshots = [
                  { sources = job.paths ++ optional job.backupStaging "/var/lib/rustic-backup-${name}/staging"; }
                ];
              };
            }
          );
        }
      ) jobs);

    systemd.tmpfiles.rules =
      mapAttrsToList (
        name: _: "f /run/lock/rustic-backup-${name}.lock 0600 root root - -"
      ) cfg.repositories
      ++ mapAttrsToList (name: _: "f /run/lock/rustic-job-${name}.lock 0600 root root - -") jobs;
    systemd.services = mapAttrs' (
      name: job:
      nameValuePair "rustic-backup-${name}" {
        description = "Rustic backup: ${name}";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ] ++ job.requiresUnits;
        requires = job.requiresUnits;
        unitConfig.RequiresMountsFor = job.paths ++ job.requiresMountsFor;
        path = [
          cfg.package
          pkgs.coreutils
          pkgs.util-linux
        ]
        ++ job.runtimePackages;
        serviceConfig = credentials job.repository cfg.repositories.${job.repository} // {
          Type = "oneshot";
          ExecStart = jobScript name job;
          StateDirectory = "rustic-backup-${name}";
          StateDirectoryMode = "0700";
          TimeoutStartSec = job.timeout;
          TimeoutStopSec = "5min";
          KillMode = "mixed";
          Nice = job.nice;
          IOSchedulingClass = "idle";
          MemoryMax = job.memoryMax;
        };
      }
    ) jobs;
    systemd.timers = mapAttrs' (
      name: job:
      nameValuePair "rustic-backup-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = job.calendar;
          RandomizedDelaySec = job.randomizedDelaySec;
          Persistent = job.persistent;
        };
      }
    ) (filterAttrs (_: job: job.calendar != null) jobs);
  };
}
