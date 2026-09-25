# Rustic backups

`modules/rustic-backup.nix` provides `services.rusticBackup`. Whale imports it
through `machines/whale/backup.nix`. The `mail` job in `machines/whale/mail.nix`
backs up `/persist/mail/vmail`, `/persist/mail/sieve` and `/persist/mail/dkim`
live, without stopping the mail container or staging a copy. It inherits the
04:00 Europe/Moscow schedule with up to 15 minutes jitter. Concurrent delivery
or mailbox changes can make a snapshot inconsistent across files; this is an
accepted tradeoff. Deployed on 2026-09-24; the timer is enabled and mail snapshots
have been verified in the repository.

Vaultwarden, Radicale and Forgejo also have daily jobs declared in their server
profiles. Vaultwarden and Forgejo include an uncompressed custom-format PostgreSQL
dump from staging alongside their data directories. All three jobs were deployed
and completed successfully on 2026-09-24; repository metadata check passed.
Initial snapshots: Vaultwarden `bc3db905`, Radicale `46734315`, Forgejo `9a1d3946`.

Five additional daily jobs were deployed and completed on 2026-09-24:

| Job | Live directories | Prepared database copies in staging |
| --- | --- | --- |
| `hass` | `/persist/hass/config` | `hass.dump` (PostgreSQL custom format), `zigbee.db` |
| `esphome` | `/var/lib/esphome` | None |
| `nextcloud` | `/persist/nextcloud/config`, `/home/alex/tank/nextcloud` | `nextcloud.sql` (MariaDB transaction dump) |
| `open-webui` | `/persist/open-webui/data` | `webui.db`, `vector_db/chroma.sqlite3` |
| `bambuddy` | `/persist/bambuddy/data` | `bambuddy.db` |

Verified snapshots: `hass` `704ac1a0`, `esphome` `5016d765`, `nextcloud`
`dbfd7420`, `open-webui` `db6ebd20`, `bambuddy` `0d20acb8`. All five services
completed successfully; repository metadata check passed and staged database
files were confirmed in the snapshots. All nine daily timers are active.

These jobs use the same 04:00 schedule and credentials; different jobs can run concurrently. PostgreSQL
and MariaDB dumps use the tools inside their database containers. SQLite uses Python
[online backup](https://www.sqlite.org/backup.html) inside the application container
so that SQLite and its locks share the application runtime (including gVisor); the live database files and
their WAL/SHM/journal companions are excluded, while prepared copies are included
from `/var/lib/rustic-backup-JOB/staging`. A missing database or failed dump aborts
the job. SQLite copies preserve source ownership and mode. Temporary SQLite copies are
created on the application data volume and streamed to host staging, then removed.
An interrupted container process may leave a `.rustic-*` temporary directory.
Hooks use the configured Podman package, including whale's extra OCI runtimes.

ESPHome excludes `.esphome/{build,platformio,.espressif,.uv_cache}`; YAML, secrets,
`.esphome/storage` and other configuration remain included. Bambuddy includes
archives and firmware, but not its separate logs directory. Nextcloud's external
`Downloads` and `Import` mounts are **not** covered by this job. Redis and raw
PostgreSQL/MariaDB data directories are not backed up.

Services remain running. Each database dump is internally consistent, but the
files and separate databases are not a single atomic snapshot. This also applies
to Open WebUI's Chroma SQLite database and vector files. For strict Nextcloud
file/database consistency, its [documented procedure](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)
uses maintenance mode; this job does not enable it.

On restore, stop the affected application first and restore into a separate
location for inspection. Restore the directory tree and then place each staged
SQLite copy at its original path (for example, `zigbee.db` into
`/persist/hass/config/zigbee.db`), preserving numeric ownership and mode. Remove
stale WAL/SHM/journal files at the destination before starting the application.
Import `hass.dump` with `pg_restore` into the recreated `hass` database and
`nextcloud.sql` with the MariaDB client into the recreated `nextcloud` database;
recreate database users from service configuration. Dumps do not include cluster
roles. Application restore drills for these five jobs are still pending.

The `yandex` repository uses the single COLD bucket `averylex-backups-whale`
with `root = "/"`. All data and metadata live in this bucket; no hot repository
is configured. Bucket configuration is managed separately from NixOS.

Verified on whale on 2026-09-24: built and activated, versioning enabled,
uploaded objects use COLD, smoke snapshot `fedd17da` restored byte-for-byte and
`check --read-data` passed. The tiny test snapshot remains; local test files
were removed. The existing S3 credentials and repository password were reused.

## Additional apps

Nine further apps were deployed and backed up successfully on 2026-09-24,
using the default 04:00 schedule:

| Job | Sources and prepared databases |
| --- | --- |
| `avitobot` | PostgreSQL `wondercraft.dump`; remote `wondercraft-media` S3 objects are outside this job |
| `wakapi` | `/persist/wakapi/data` + `wakapi.dump` |
| `litellm` | `litellm.dump`; declarative app config remains in Git |
| `cliproxyapi` | Config YAML, auths and usage-keeper, with online `app.db` copy |
| `navidrome` | Data for enabled instances, with online `INSTANCE/navidrome.db` copies |
| `lidarr` | Config and online `lidarr.db` copy |
| `prowlarr` | Config and online `prowlarr.db` copy |
| `qbit` | `/persist/qbit/config` and `/home/alex/tank/Torrents` (standalone `.torrent` files); excludes logs, lockfile and IPC socket |
| `slskd` | `/persist/slskd` with online copies of transfers, events, messaging and search databases |

SQLite copies are staged at `/var/lib/rustic-backup-JOB/staging`, replacing live
SQLite files and WAL/SHM/journal companions in the backup. The shared helper
`apps/lib/sqlite-backup.nix` runs inside the owning container; it uses Navidrome's
existing SQLite CLI and mounts a static SQLite CLI read-only for the other four
apps. These mounts were activated at deployment with a restart of those four containers. Temporary copies are made on the application volume, streamed to staging,
and cleaned up; abrupt termination can leave `.rustic-backup.*` directories.
The SQLite helper pins a read transaction during the online copy so continuous
writes do not restart the copy. Ownership and modes are preserved on staged databases. Restore the directories
and replace excluded SQLite databases from staging before starting the app,
removing stale destination WAL/SHM/journal files first.

Logs, Navidrome cache, Lidarr/Prowlarr built-in Backups, usage-keeper historical
backups, slskd historical database backups and its share-cache backup are excluded.
Music and downloaded content are outside these jobs, including slskd's local
`downloads` and `incomplete` directories. All apps stay running during backups;
separate databases and files are not an atomic snapshot. The retired Navidrome
`ssk8q` directory was deleted at the user's request; only enabled instances are
covered. Verified successful snapshots: Avitobot `6842cb26`, Wakapi `5cd5ec61`, LiteLLM
`1e7e2d20`, CLIProxyAPI `45bf7b46`, Navidrome `f423b63d`, Lidarr `fbf5ff81`,
Prowlarr `84ca3404`, qBit `8bd786f6`, slskd `2724b17b`. Application restore drills
remain pending. No repository-wide check was run during the active Immich backup.

The addition of `/home/alex/tank/Torrents` to qBit was deployed on 2026-09-25;
snapshot `a0572608` completed successfully. The general tank job excludes it.

## Personal tank

The `tank` job backs up `/home/alex/tank`. Both nested filesystems, `hot` and
`cold`, are excluded for now and are not mount dependencies of this job. It inherits the daily 04:00 Europe/Moscow schedule
and 15-minute jitter, with a 7-day timeout for the initial multi-terabyte upload.
It has its own job lock and can run alongside other backups. Files are read live.

Excluded paths relative to tank:

- `Immich`, `nextcloud`, `Torrents`: dedicated jobs; Immich generated content is
  intentionally omitted altogether. Deploy the qBit Torrents addition together
  with this job.
- `hot` and `cold`: both entire filesystems, excluded at the user's request for now.
- `.snapshots` at any depth, plus root `.Trash-1000` and `.mypy_cache`.

Everything else is included, notably `Archive`, `Обработать`,
`Restored`, `Дроны`, root `Downloads`, `migration-backups`, `OpenWebUI-backups` and
`Archive/Some_torrents`. These are path exclusions: files moved or hard-linked
outside an excluded directory are included when their other path is scanned.
Deployed on 2026-09-25. The first backup started at 11:45 MSK and began uploading
successfully with the exclusions verified in the live profile. Completion of the
first snapshot and restore verification remain pending.

## Immich

Deployed on 2026-09-24 together with per-job locks. The first backup was started
manually; the PostgreSQL dump completed and rustic began uploading media.
Completion and restore verification of that first snapshot are still pending.

The `immich` job backs up `/home/alex/tank/Immich/{library,upload,profile}`
with a fresh, uncompressed custom-format PostgreSQL dump (`immich.dump`) and
`container-images.txt` in staging. The latter records the actual container image
names and IDs at backup time. The dump uses the database container's own tools.
Immich stays running; concurrent uploads, deletions and moves can cause differences
between the database and files. No application pause or Btrfs snapshot is used.

The job runs daily at 06:00 Europe/Moscow plus up to 15 minutes jitter, after the
usual smaller jobs, with a 48-hour timeout for the first roughly 1.2 TiB upload.
Other jobs can run during the initial upload; they share disk, network and memory
resources. Repository administration through the helper waits for active backups.

Thumbnails, encoded videos, built-in historical database dumps, raw PostgreSQL
files, model cache and Valkey are outside this job. On restore, use a compatible
Immich/PostgreSQL image and extensions, restore the originals to their original
container paths, and import the custom-format dump with `pg_restore` into a fresh
database before starting Immich. Regenerate thumbnails and encoded videos
following the [Immich restore guide](https://docs.immich.app/administration/backup-and-restore/).
Database restoration and regeneration have not yet been tested for this job.

## Provision credentials and initialize

From the dotfiles root, using the existing agenix identity:

```sh
agenix -e secrets/creds/rustic-whale-s3.age
```

This file is a systemd EnvironmentFile:

```text
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

The repository encryption password lives only on whale at
`/persist/rustic/repository-password` (root:root, mode 0600; parent directory 0700).
It is not managed by agenix and must not be added to this repo, even encrypted.
The backup units load it at runtime with systemd LoadCredential. Keep an independent
recovery copy outside whale; rebuilding the host requires restoring this file
before running backups. Do not generate a new password for the existing repository.

Only the S3 credentials are in the secrets Git submodule. Their ACL entry in
`secrets/secrets.nix` authorizes alex and whale. Never use Nix strings or
`builtins.readFile` for plaintext secrets.

Before uploading, check in Yandex Cloud:

- The bucket defaults to COLD and has versioning enabled.
- The production service account has `storage.uploader` on this bucket
  and no inherited broader role. This role permits overwrites, not just new uploads.
- No lifecycle expiration of current objects. Optional noncurrent expiration
  after 180 days is an operational recovery window, not immutable retention.
- Maintenance credentials stay off whale. This module never automatically
  initializes, forgets or prunes a repository.

Track new module files, then build on the target:

```sh
./deploy.sh whale build
./deploy.sh whale switch
```

On whale, the installed root-only helper loads the same credentials and takes
an exclusive repository maintenance lock, waiting for active backup jobs. Arguments pass directly to rustic:

```sh
sudo rustic-backup-yandex init     # Once, only for the new repository
sudo rustic-backup-yandex snapshots
sudo rustic-backup-yandex check
```

The helper runs through a transient systemd service; passwords are passed with
LoadCredential, S3 credentials through EnvironmentFile. Plain `rustic -P ...`
does not load these secrets automatically. Do not bypass the helper for concurrent
repository maintenance. The lock only coordinates commands on this host.

For the initial end-to-end test, create a small disposable source on whale,
back it up with `sudo rustic-backup-yandex backup /path/to/test-source`, inspect
the returned snapshot with `ls`, then restore its source subtree to a separate
empty directory using `restore SNAPSHOT:/absolute/source /path/to/restore`.
Compare the restored content. Do not point a trial restore at live application
data. This uploads a real, small snapshot; no destructive cleanup is automated.

## Declare a directory backup

In any module imported by whale:

```nix
services.rusticBackup.jobs.documents = {
  paths = [ "/home/alex/tank/documents" ];
  exclude = [ "**/.cache/**" "**/.snapshots/**" ];
};
```

Defaults on whale are daily at 04:00 Europe/Moscow, up to 15 minutes jitter,
catch-up after downtime, 12-hour timeout, nice 10 and 2 GiB MemoryMax. Override
per job using `calendar`, `randomizedDelaySec`, `persistent`, `timeout`, `nice`
and `memoryMax`. Change all jobs through `services.rusticBackup.defaults`.
Normal `lib.mkDefault`/`lib.mkForce` semantics apply; source lists merge normally.

```nix
services.rusticBackup.jobs.documents.calendar = "*-*-* 00/6:00:00";
# Or calendar = null; for manual-only jobs.
```

`exclude` takes patterns without a leading `!`; the module translates them into
rustic's exclusion globs. Sources automatically populate `RequiresMountsFor`.
Use `requiresMountsFor` for additional paths needed by hooks. A path must have a
declared mount if it is supposed to depend on a separate filesystem.

## Prepare a database dump

```nix
{ pkgs, ... }:
{
  services.rusticBackup.jobs.myapp = {
    calendar = "*-*-* 00/6:00:00";
    runtimePackages = [ pkgs.postgresql_14 ];
    requiresUnits = [ "postgresql.service" ];
    backupStaging = true;
    prepareScript = ''
      runuser -u postgres -- pg_dump --format=custom myapp \
        > "$BACKUP_STAGING_DIR/myapp.dump"
    '';
  };
}
```

This example covers one database only; cluster roles and application files need
their own explicit coverage. For consistent database/files pairs, arrange an
application-specific pause/snapshot procedure in prepare/cleanup hooks.

Hooks run as root with strict shell error handling and `runtimePackages` on PATH:

1. Acquire the exclusive job lock and shared repository maintenance lock, then
   recreate the private staging directory.
2. Run `prepareScript`. Failure aborts the backup.
3. Back up `paths` and optionally staging. Hostname, label and `job:NAME` tag
   identify snapshots; the source staging path is stable across runs.
4. Run `successScript` only after rustic exits successfully.
5. Run `cleanupScript` on success, error or handled termination, then remove staging.

Cleanup must be idempotent and handle partially completed preparation. Its failure
fails the job, too. Power loss/SIGKILL cannot execute hooks; services paused during
backup need a recovery procedure. Staging is `/var/lib/rustic-backup-NAME/staging`.
Whale automatically persists each enabled job's working directory on `/persist`,
so database dumps do not fill its tmpfs root. Old staging contents are removed
before every run. The repository cache is also persisted.

`extraSettings` extends rustic's `[backup]` table, for example
`extraSettings."skip-if-unchanged" = true`. Source, host, label, tags and globs
remain module-owned; use the dedicated options for those. Extra settings and
hooks are trusted configuration and can alter rustic behavior; never put secrets
in them.

Additional systemd customization is available through the generated units:

```nix
systemd.services.rustic-backup-myapp.serviceConfig.TimeoutStopSec = "10min";
systemd.services.rustic-backup-myapp.onFailure = [ "my-alert.service" ];
```

## Operate and verify

```sh
sudo systemctl start rustic-backup-myapp.service
systemctl status rustic-backup-myapp.service
journalctl -u rustic-backup-myapp.service
systemctl list-timers 'rustic-backup-*'
sudo rustic-backup-yandex snapshots
```

Different jobs can run concurrently, including in the same repository. Each job
holds its own exclusive lock through preparation, backup and cleanup to protect
its staging directory. Jobs also hold a shared repository lock; the admin helper
holds that lock exclusively for every command (including `snapshots` and `check`).
This keeps maintenance separate from backups on this host. Locks do not coordinate
other machines. The timeout includes waiting for locks.
No job is considered configured merely because the repository is initialized:
add sources explicitly, test restores, and connect failure/stale-backup alerts
when enrolling production services. Automated checks, retention and remote
maintenance scheduling are not enabled by this infrastructure module.

With this single repository, rustic no longer defaults to metadata-only repacking
as it does with `repo-hot`. Decide the repacking limits when adding maintenance;
versioning keeps deleted packs billable until their old versions are expired.

The module evaluation checks live in `tests/rustic-backup.nix`. With the pinned
nixpkgs path, evaluate its `checks` attribute; this does not build any host.

References: [rustic hot/cold storage](https://rustic.cli.rs/docs/commands/init/cold_storage.html),
[rustic 0.11.4 configuration](https://github.com/rustic-rs/rustic/blob/v0.11.4/config/full.toml).
