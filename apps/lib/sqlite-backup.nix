# Online SQLite copies must run inside the application's runtime (e.g. gVisor).
{ lib, pkgs }:
{
  container,
  databases,
  sqlite ? "/run/rustic-sqlite3",
}:
{
  volume = "${pkgs.pkgsStatic.sqlite}/bin/sqlite3:/run/rustic-sqlite3:ro";
  exclude = lib.concatMap (
    db:
    map (suffix: db.host + suffix) [
      ""
      "-wal"
      "-shm"
      "-journal"
    ]
  ) databases;
  prepareScript = lib.concatMapStringsSep "\n" (db: ''
    mkdir -p -- "$BACKUP_STAGING_DIR/$(dirname ${lib.escapeShellArg db.target})"
    podman exec --user root ${lib.escapeShellArg container} sh -eu -c ${lib.escapeShellArg ''
      source=${lib.escapeShellArg db.path}
      test -f "$source"
      tmp=$(mktemp -d "$(dirname "$source")/.rustic-backup.XXXXXX")
      trap 'rm -rf -- "$tmp"' EXIT
      ${lib.escapeShellArg sqlite} -readonly "$source" ".timeout 10000" \
        "BEGIN; SELECT count(*) FROM sqlite_schema;" ".backup '$tmp/database'" "ROLLBACK;" >/dev/null
      cat "$tmp/database"
    ''} > "$BACKUP_STAGING_DIR/"${lib.escapeShellArg db.target}
    chown --reference=${lib.escapeShellArg db.host} "$BACKUP_STAGING_DIR/"${lib.escapeShellArg db.target}
    chmod --reference=${lib.escapeShellArg db.host} "$BACKUP_STAGING_DIR/"${lib.escapeShellArg db.target}
  '') databases;
}
