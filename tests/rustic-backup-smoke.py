"""Run built test profiles/scripts in a disposable local directory.

Arguments: manifest JSON (checks/profiles/executables from rustic-backup.nix),
rustic executable. This exercises generated scripts, not systemd or S3.
"""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time


manifest = json.loads(Path(sys.argv[1]).read_text())
rustic = sys.argv[2]
assert all(manifest["checks"].values())


def run(args, *, env, expected=0):
    result = subprocess.run(args, env=env, text=True, capture_output=True)
    assert result.returncode == expected, (args, result.returncode, result.stdout, result.stderr)
    return result.stdout


with tempfile.TemporaryDirectory(prefix="rustic-smoke-") as directory:
    root = Path(directory).resolve()
    for name in ("source", "profiles", "locks", "state", "bin", "credentials"):
        (root / name).mkdir()
    (root / "credentials/repository-password").write_text("disposable test password\n")
    (root / "source/keep.txt").write_text("restore this content\n")
    (root / "source/skip.tmp").write_text("exclude this content\n")
    # macOS has no util-linux flock. Use its flock syscall on the inherited FD.
    lock = root / "bin/flock"
    lock.write_text(f"#!{sys.executable}\nimport fcntl,sys\nfcntl.flock(int(sys.argv[-1]), fcntl.LOCK_SH if '-s' in sys.argv else fcntl.LOCK_EX)\n")
    lock.chmod(0o700)
    env = os.environ | {
        "CREDENTIALS_DIRECTORY": str(root / "credentials"),
        "RUSTIC_PASSWORD_FILE": str(root / "credentials/repository-password"),
        "PATH": f"{root / 'bin'}:{os.environ['PATH']}",
    }
    for name, path in manifest["profiles"].items():
        content = Path(path).read_text().replace("/tmp/rustic-module-test", str(root))
        content = content.replace("/var/cache/rustic-backup-local", str(root / "cache"))
        content = content.replace("/var/lib/", f"{root}/state/")
        target = f"backup-{'repository-local' if name == 'repository' else 'job-' + name}.toml"
        (root / "profiles" / target).write_text(content)
    base = [rustic, "-P", str(root / "profiles/backup-repository-local.toml")]
    run(base + ["init"], env=env)
    for name, path in manifest["executables"].items():
        script = Path(path).read_text().replace("/run/lock/", f"{root}/locks/")
        script = script.replace("/var/lib/", f"{root}/state/")
        script = script.replace("/etc/rustic/", f"{root}/profiles/")
        target = root / name
        target.write_text(script)
        target.chmod(0o700)
        run([str(target)], env=env)
        assert not (root / f"state/rustic-backup-{name}/staging").exists()
    # Exercise the lock prefix of the generated scripts with overlapping processes.
    def locked_process(name, token, *, maintenance=False):
        prefix = (root / name).read_text().split("export BACKUP_STAGING_DIR=", 1)[0]
        if maintenance:
            prefix = re.sub(r"^.*(?:exec 8>|flock 8).*$", "", prefix, flags=re.MULTILINE)
            prefix = prefix.replace("flock -s 9", "flock 9")
        ready = root / token
        process = subprocess.Popen(
            ["bash", "-c", prefix + f"\ntouch '{ready}'\nread -r release\n"],
            env=env, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True,
        )
        return process, ready

    def await_ready(process, ready):
        deadline = time.monotonic() + 5
        while not ready.exists() and time.monotonic() < deadline:
            assert process.poll() is None, process.communicate()
            time.sleep(0.02)
        assert ready.exists(), f"lock acquisition timed out: {ready}"

    running = []
    try:
        first, first_ready = locked_process("files", "first-ready")
        running.append(first)
        await_ready(first, first_ready)
        other, other_ready = locked_process("dump", "other-ready")
        running.append(other)
        await_ready(other, other_ready)  # Different job, same repository: concurrent.
        duplicate, duplicate_ready = locked_process("files", "duplicate-ready")
        running.append(duplicate)
        admin, admin_ready = locked_process("dump", "admin-ready", maintenance=True)
        running.append(admin)
        time.sleep(0.2)
        assert not duplicate_ready.exists() and not admin_ready.exists()
        first.communicate("release\n", timeout=5)
        await_ready(duplicate, duplicate_ready)
        other.communicate("release\n", timeout=5)
        assert not admin_ready.exists()  # Duplicate still owns a shared lock.
        duplicate.communicate("release\n", timeout=5)
        await_ready(admin, admin_ready)
        blocked, blocked_ready = locked_process("files", "blocked-ready")
        running.append(blocked)
        time.sleep(0.2)
        assert not blocked_ready.exists()
        admin.communicate("release\n", timeout=5)
        await_ready(blocked, blocked_ready)
        blocked.communicate("release\n", timeout=5)
        assert all(p.returncode == 0 for p in running)
    finally:
        for process in running:
            if process.poll() is None:
                process.kill()
                process.communicate()

    run(base + ["check", "--read-data"], env=env)
    # Select by stable job label; dump was backed up later.
    snapshots = json.loads(run(base + ["snapshots", "--json"], env=env))
    # Rustic returns snapshot groups, each with a snapshots array.
    def collect(value):
        if isinstance(value, dict):
            if "id" in value and "label" in value:
                yield value
            else:
                for child in value.values():
                    yield from collect(child)
        elif isinstance(value, list):
            for child in value:
                yield from collect(child)
    by_label = {snapshot["label"]: snapshot for snapshot in collect(snapshots)}
    for name, source, filename, content in (
        ("files", root / "source", "keep.txt", "restore this content\n"),
        ("dump", root / "state/rustic-backup-dump/staging", "database.sql", "dump fixture"),
    ):
        destination = root / f"restored-{name}"
        run(base + ["restore", f"{by_label[name]['id']}:{source}", str(destination)], env=env)
        assert (destination / filename).read_text() == content
    assert not (root / "restored-files/skip.tmp").exists()

    # Inject failures into copies of the actual generated orchestrator script.
    original = (root / "dump").read_text()
    marker = root / "cleanup-ran"
    for phase in ("prepare", "backup", "cleanup"):
        script = re.sub(r"/nix/store/[^\s]+-rustic-dump-cleanup", f"touch {marker}", original)
        if phase == "backup":
            script = re.sub(r"^.* -P .* backup$", "exit 23", script, flags=re.MULTILINE)
        elif phase == "prepare":
            script = re.sub(r"/nix/store/[^\s]+-rustic-dump-prepare", "exit 23", script)
        else:
            script = script.replace(f"touch {marker}", f"touch {marker}; (exit 23)")
        target = root / f"fail-{phase}"
        target.write_text(script)
        target.chmod(0o700)
        before = run(base + ["snapshots", "--json"], env=env)
        run([str(target)], env=env, expected=23)
        assert marker.exists(), f"cleanup missing after {phase} failure"
        marker.unlink()
        assert not (root / "state/rustic-backup-dump/staging").exists()
        if phase != "cleanup":
            assert run(base + ["snapshots", "--json"], env=env) == before

print("PASS: module options, concurrent jobs, duplicate/maintenance exclusion, backup/restore, exclusions, dump staging, prepare/backup/cleanup failures")
