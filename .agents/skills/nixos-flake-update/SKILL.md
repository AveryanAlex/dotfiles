---
name: nixos-flake-update
description: Update this dotfiles repo's flake inputs, repair update regressions, deploy requested NixOS hosts on the correct builders, verify live health, and commit the resulting repo changes. Use for end-to-end flake update and rollout requests; do not use for a build-only check or an unrelated package change.
---

# NixOS Flake Update

Perform the update as a gated rollout. A successful evaluation is not enough: each requested host must build in the permitted place, switch successfully, and pass live health checks before proceeding to the next host.

## Before Updating

1. Read the root `AGENTS.md` and any child guide for files that may need changes.
2. Run `hostname`, `git branch --show-current`, `git status --short --branch`, and inspect recent commits.
3. Preserve pre-existing commits and user changes. Do not let unrelated work enter update commits; stop for direction if existing changes overlap the update.
4. Record the requested rollout order. Never switch a host the user did not request.

## Update the Lock File

Run as the normal user:

```bash
nix flake update --commit-lock-file
```

The flag is `--commit-lock-file`, not `--commit-lock file`. The command creates its own `flake.lock: Update` commit. Verify the new commit and worktree immediately afterward. Do not amend or rewrite earlier history unless explicitly requested.

## Build and Switch the Current Host

Only the machine returned by `hostname` may be built locally. Build without `sudo` so private Git inputs use the user's SSH keys and known-hosts file:

```bash
nixos-rebuild build --flake . --show-trace
```

After a successful build, switch with privileged activation while retaining user-side evaluation:

```bash
nixos-rebuild switch --flake . --sudo --show-trace
```

Do not run the whole build under `sudo`: root may lack SSH trust or credentials for the private secrets input.

## Build and Switch Another Host

Never build another machine's NixOS configuration locally. Use the repository deployment wrapper, which sets both the target and build host:

```bash
./deploy.sh <hostname> build
./deploy.sh <hostname> switch
```

Do not switch until `build` has completed successfully. If compatibility fixes change the evaluated configuration, rebuild the affected host before switching.

## Diagnose Failures

Find the first failed derivation; the later `dependency failed` messages are usually fallout.

- Evaluation, removed-option, assertion, or compile errors require a minimal repo-consistent fix.
- For a fetch failure, inspect `nix log <drv>`. A TLS timeout or temporary mirror/proxy failure should be retried before changing configuration. It can be useful to realize the exact failed fixed-output derivation, then rerun the full host build.
- Treat upstream deprecation warnings as findings, not local incompatibilities, unless the trace points to code owned by this repo.
- After a fix, format relevant repo files and rerun the failed host build. Never use another host's local toplevel build as a shortcut.

## Health Gates

For every switched host, verify the activated generation and system manager:

```bash
readlink -f /run/current-system
nixos-version
systemctl is-system-running
systemctl --failed --no-legend --no-pager
```

Also check the services that define that host's role, and inspect errors since the switch rather than dumping unrelated historical logs.

For a desktop:

- check `systemctl --user is-system-running` and user failed units;
- verify the desktop shell/compositor integration and key networking, proxy, container, and sync services;
- distinguish persistent failures from harmless activation-time D-Bus re-registration noise.

For `whale`:

- check networking, CoreDNS, nftables, nginx, SSH, Nebula/Yggdrasil, Mihomo, Incus, PostgreSQL/MySQL, Matrix, Forgejo, Vaultwarden, Syncthing, and exporters;
- verify both `mailserver` and `pterodactyl` appear in `machinectl list`, and use privileged machine-manager checks when inspecting their internal systemd state;
- inspect every rootful Podman container with `sudo podman ps -a` and `sudo podman inspect`; all long-running containers must be running, and every declared health check must be healthy;
- allow one bounded startup interval for dependency-heavy applications, then recheck restarts and recent logs.

Errors caused by the planned stop/start window are not regressions if the unit recovered and no new errors continue. Confirm this with current state, restart counts, and post-start timestamps.

If PostgreSQL reports a collation-version mismatch, do not merely refresh the version. Confirm the exact database and actual versions, then—when the requested maintenance scope permits it—reindex that database before `ALTER DATABASE ... REFRESH COLLATION VERSION`. Verify application and maintenance databases afterward. This mutates live database state, so keep the target explicit and do not generalize the command across unrelated database containers.

## Finish

1. Run `treefmt` for repo changes.
2. Run `nix flake check --no-build`. This evaluates every NixOS configuration and can reveal errors masked by an earlier failure, while avoiding a forbidden local build of another host. Fix evaluation incompatibilities, but use only the permitted host-specific commands above for real builds.
3. Recheck both local and remote health after services have stabilized.
4. Review `git diff`, `git status`, and the commits created during the workflow.
5. Commit compatibility or workflow changes separately from the automatic lock-file commit with a semantic message. Do not include unrelated changes.
6. Report the activated store paths, health result, any remaining non-blocking warnings, external state repairs, and commit hashes.
