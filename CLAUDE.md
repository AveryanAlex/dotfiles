# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

See `AGENTS.md` for comprehensive documentation including container app patterns, examples, and detailed guidelines.

## Commands

```bash
nh os build                              # Build current system (no switch)
nh os switch                             # Deploy to local machine
./deploy.sh <hostname> [switch|build]    # Deploy to remote machine
nix flake check                          # Evaluate flake for errors
treefmt                                  # Auto-format (nixfmt)
treefmt --ci                             # Check formatting
nix flake update --commit-lock-file      # Update all inputs
nixos-rebuild build --flake .#<hostname> # Build specific machine
```

## Critical: Git + Nix Interaction

Nix ignores files unknown to git. After creating **new** files, run `git add <new-files>` before building. Modified tracked files don't need staging.

## Architecture

NixOS flake managing 5 machines (alligator, hamster, ferret, whale, lizard). The flake auto-discovers machines from `machines/` directories, reads `system.txt` for architecture, and provides `inputs` and `secrets` (path to `./secrets`) via `specialArgs`.

**Hierarchy:** `core` role (base for all) -> `desktop`/`server`/`family` roles -> machine configs. Machines import roles, never `core` directly.

**Key directories:**
- `machines/<hostname>/` — Per-machine config (`default.nix`, `hardware.nix`, `mounts.nix`, `system.txt`)
- `roles/` — Role compositions that bundle profiles (core, desktop, dev, server, family)
- `profiles/` — Reusable config units; `profiles/server/` for server services
- `modules/` — Custom NixOS modules with `options`/`config` (nebula, persist, tproxy, xray, mihomo)
- `apps/` — Containerized services (Podman/Quadlet) on whale
- `hardware/` — Hardware-specific modules
- `secrets/` — Git submodule with age-encrypted secrets (ragenix)

## Code Conventions

- Formatter: **nixfmt** (enforced in CI)
- Module files: `lowercase-with-dashes.nix`
- Variables: camelCase
- Home-manager shorthand: `hm.` aliases `home-manager.users.alex`
- Secrets: `age.secrets.<name>.file = "${secrets}/creds/<name>.age";` (use `secrets` from specialArgs)
- Imports: relative paths (`../../roles/desktop`, `./hardware.nix`)

## Module Pattern

```nix
{ lib, config, pkgs, inputs, secrets, ... }:
with lib;
let cfg = config.namespace.optionName;
in {
  options.namespace.optionName.enable = mkEnableOption "description";
  config = mkIf cfg.enable { /* ... */ };
}
```

## Container Apps (whale)

Each app in `apps/<name>/` gets: isolated `10.90.X.0/24` subnet, Podman Quadlet containers, nginx reverse proxy with `useACMEHost = "averyan.ru"`, agenix secrets, and data in `/persist/<name>/`. See `AGENTS.md` for full patterns and examples.
