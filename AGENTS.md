# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-12
**Commit:** d97eea8
**Branch:** main

## OVERVIEW

Flake-based NixOS/Home Manager repo for multiple machines.
`flake.nix` auto-discovers `machines/`, `hardware/`, and `modules/`; roles, profiles, and apps are imported explicitly.

## STRUCTURE

```text
.
├── machines/           # Per-host entrypoints; whale is the complex server outlier
├── roles/core/         # Base system, networking, podman, shell, hm wiring
├── roles/desktop/      # Desktop stack; imports dev automatically
├── roles/dev/          # Editor/tooling/AI configs for desktop machines
├── profiles/           # Reusable host/service modules
├── profiles/server/    # Native NixOS services for whale
├── apps/               # Quadlet/Podman apps imported by whale
├── modules/            # Custom NixOS modules auto-exported by the flake
├── hardware/           # Auto-exported hardware modules
├── secrets.nix         # Agenix public-key ACL manifest
└── secrets/            # Encrypted secret files (git submodule)
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a new machine | `machines/<host>/` | `system.txt` sets arch; the flake discovers the host automatically |
| Change cross-machine base behavior | `roles/core/` | Networking, podman, shell, system profile bus |
| Change desktop behavior | `roles/desktop/` | Desktop already imports dev |
| Change dev/editor tooling | `roles/dev/` | Packages, overlays, VS Code/Zed/AI configs |
| Add a native whale service | `profiles/server/<name>.nix` | Import it from `machines/whale/default.nix` |
| Add a containerized whale service | `apps/<app>/` | See `apps/AGENTS.md` |
| Change custom option modules | `modules/` | Auto-exported as `inputs.self.nixosModules.modules.*` |
| Change whale-only topology | `machines/whale/` | Bridges, DNS, mail container, routing |
| Add or rotate a secret | secret file + `secrets.nix` | Every new `.age` file also needs a root ACL entry |

## CHILD GUIDES

- `apps/AGENTS.md` — Quadlet app conventions, subnet registry, UID/GID schemes, networking extras
- `machines/whale/AGENTS.md` — whale-only topology, mail container, DNS, ingress rules
- `roles/core/AGENTS.md` — cross-machine networking/podman/shell invariants
- `profiles/server/AGENTS.md` — native whale service patterns
- `modules/AGENTS.md` — custom NixOS module conventions and module coupling

## CONVENTIONS

- Prefer relative imports for `roles/`, `profiles/`, and same-directory files.
- `flake.nix` auto-discovers `machines/`, `hardware/`, and `modules/`. New files there need no manual registration. `roles/`, `profiles/`, and `apps/` still require explicit imports.
- Machines normally import a top-level role (`roles/desktop`, `roles/server.nix`, `roles/family.nix`). `lizard` is the intentional exception and imports `roles/core` directly.
- `desktop` already imports `../dev`; do not add `roles/dev` directly in machine configs.
- `inputs` and `secrets` are passed through `specialArgs`. Use `"${secrets}/..."` for shared secrets and relative `./file.age` paths for app-local secrets.
- The repo is flakes-only: `nix.channel.enable = false`.
- `hm` is shorthand for `home-manager.users.alex`, provided by the external `nixcfg` input. It is not defined locally.
- Persistent host data usually goes through `persist.state`, `persist.derivative`, or `persist.cache`. App containers are the main exception: they usually create `/persist/<app>/...` via `systemd.tmpfiles.rules`.
- Hardware modules are referenced as `inputs.self.nixosModules.hardware.<name>`; custom modules as `inputs.self.nixosModules.modules.<name>`.
- CI is split: GitHub Actions handles formatting and flake.lock updates; Woodpecker runs lint plus `nix flake check`.

## ANTI-PATTERNS

- Do not import from `archive/`; it is dead code.
- Do not put Quadlet apps in `profiles/server/` or native NixOS services in `apps/` unless the host-coupling is intentional and obvious.
- Do not commit unencrypted secrets or forget the matching `secrets.nix` ACL entry.
- Do not assume new files are visible to Nix until they are tracked by git.
- Do not fall back to nix channels, legacy DHCP, or Avahi defaults; this repo is built around flakes, `systemd-networkd`, and `systemd-resolved`.

## COMMANDS

```bash
treefmt
nix run nixpkgs#nixfmt-tree -- --ci
nix flake check
nh os build
nixos-rebuild build --flake .#<hostname>
./deploy.sh <hostname> [switch|boot|test]
nix flake update --commit-lock-file
```

## NOTES

- `nix flake check` is still useful, but the repo currently has known non-blocking noise around `colmenaHive` and some existing machine warnings.
- `deploy.sh` builds on the target host (`--build-host <hostname>`), not locally.
- When root guidance and a child AGENTS file overlap, the child file wins for that subtree.
