# AGENTS.md

Instructions for AI coding agents working on this NixOS configuration repository.

## Overview

This is a NixOS system configuration using flakes. It defines multiple machines (whale, lizard, alligator, hamster, ferret, etc.) with shared profiles, modules, and roles.

**Current Active Machines:**
- **alligator** - Desktop with NVIDIA, uses `roles/desktop`
- **hamster** - Laptop (ThinkBook), uses `roles/desktop`
- **ferret** - Laptop, uses `roles/family` (for family member "olga")
- **lizard** - RPi4 home server, minimal setup
- **whale** - Main home server with many services

**Archived Machines** (in `archive/machines/`):
- grizzly, hawk, diamond, falcon

## Commands

### Build/Deploy
- `nh os build` - Build current system without switching (safe for testing)
- `nh os switch` - Deploy to local machine
- `./deploy.sh <hostname>` - Deploy to remote machine
- `nix flake check` - Evaluate flake for errors (fast, no network needed)
- `nix flake update --commit-lock-file` - Update all inputs and commit lock file

### Formatting
- `treefmt --ci` - Check formatting for all files
- `treefmt` - Auto-format all files (uses nixfmt)

## Repository Structure

```
.
├── machines/<hostname>/     # Machine-specific configurations
│   ├── default.nix          # Main config (imports roles/)
│   ├── hardware.nix         # Hardware-specific (boot, drives)
│   ├── mounts.nix           # Filesystem mounts
│   └── system.txt           # Architecture ("x86_64-linux")
├── roles/                   # High-level role compositions
│   ├── core/               # Base system (replaces minimal+full)
│   │   ├── default.nix     # Shell, system, network, podman
│   │   ├── shell/          # zsh, git, direnv, etc.
│   │   ├── system.nix      # core profiles (boot, locale, users, etc.)
│   │   ├── network.nix     # systemd-networkd, resolved, firewall
│   │   ├── podman.nix      # containers + quadlet
│   │   └── hosts.nix       # static hosts for nebula
│   ├── desktop/            # Desktop environment
│   │   ├── default.nix     # Main desktop config
│   │   ├── apps/           # alacritty, firefox, wezterm, mpv, misc-a
│   │   ├── games/          # minecraft, xonotic
│   │   ├── gnome.nix       # GNOME DE configuration
│   │   └── ...             # compat, deployapp, distrobox, tank, tuning
│   ├── dev/                # Development tools
│   │   ├── default.nix     # Main dev config
│   │   ├── vscode.nix      # VS Code with extensions
│   │   ├── zed.nix         # Zed editor config
│   │   ├── python.nix      # Python packages
│   │   ├── docker.nix      # Rootless Docker
│   │   ├── opencode.nix    # Opencode AI tool
│   │   └── mcp.nix         # MCP servers
│   ├── family/             # Family member setup
│   │   ├── default.nix     # Aggregator
│   │   ├── users.nix       # alex + olga users
│   │   ├── userdirs.nix    # Russian XDG dirs
│   │   ├── home.nix        # Home-manager for olga
│   │   ├── firefox.nix     # Firefox config for olga
│   │   └── misc-f.nix      # Family-specific packages
│   ├── server.nix          # Server role (no sleep/hibernate)
│   └── family.nix          # Family PC role (Russian locale)
├── profiles/               # Reusable configuration units
│   ├── server/            # Server service configs (nginx, mysql, etc.)
│   ├── agenix.nix         # Secrets management
│   ├── bluetooth.nix      # Bluetooth hardware
│   ├── libvirt.nix        # VM support
│   ├── netman.nix         # NetworkManager
│   └── ...                # Other reusable modules
├── modules/               # Custom NixOS modules with options
│   ├── nebula-averyan.nix
│   ├── nebula-frsqr.nix
│   └── persist.nix
├── hardware/              # Hardware-specific modules
├── secrets/               # Encrypted secrets (agenix)
└── archive/               # Archived/dead code
    ├── machines/          # Old machine configs
    └── profiles/          # Old profile configs (gui/, autologin.nix)
```

## Import Patterns

### Current Style (Preferred)
Use **relative paths** for imports:

```nix
# In machines/<hostname>/default.nix
{
  imports = [
    ../../roles/desktop        # or roles/server.nix, roles/core, etc.
    ../../profiles/bluetooth.nix
    ../../profiles/netman.nix
    ./hardware.nix
    ./mounts.nix
  ];
}

# In roles/core/default.nix
{
  imports = [
    inputs.nixcfg.nixosModules.default
    inputs.home-manager.nixosModules.default
    inputs.self.nixosModules.modules.nebula-averyan
    ./network.nix
    ./podman.nix
    ./shell
    ./system.nix
  ];
}

# Using secrets from specialArgs (RECOMMENDED)
{
  secrets,
  ...
}:
{
  age.secrets.my-secret.file = "${secrets}/creds/my-secret.age";
}
```

### Special Args
The flake provides these in `specialArgs`:
- `inputs` - All flake inputs
- `secrets` - Path to `./secrets` directory

## Code Style

### Nix Formatting
- Use **nixfmt** formatter (enforced in CI via `.github/workflows/fmt.yml`)
- Trailing newline at end of files
- No trailing whitespace
- Run `treefmt` before committing

### Module Structure
```nix
{ lib, config, pkgs, inputs, ... }:
with lib;
let
  cfg = config.namespace.optionName;
in
{
  options = {
    namespace.optionName = {
      enable = mkEnableOption "description";
    };
  };

  config = mkIf cfg.enable {
    # configuration...
  };
}
```

### Naming Conventions
- Module files: lowercase-with-dashes.nix (e.g., `nebula-averyan.nix`)
- Option namespaces: lowercase (e.g., `networking.nebula-averyan`)
- Variable names: camelCase for Nix expressions
- Machine directories: lowercase (e.g., `alligator/`, `whale/`)

### File Organization Guidelines

When adding new modules:

1. **Role-specific** (desktop-only, server-only) → Place in `roles/<role>/`
2. **General reusable** → Place in `profiles/`
3. **Hardware-specific** → Place in `hardware/`
4. **Custom NixOS modules with options** → Place in `modules/`
5. **Machine-specific** → Place in `machines/<hostname>/`
6. **Dead/legacy code** → Move to `archive/`

**Prefer roles over profiles** when the config is role-specific.

## Home-Manager

- Available via `inputs.home-manager`
- Custom `hm` alias used throughout for `home-manager.users.alex`
- Example: `hm.home.packages = [ pkgs.ripgrep ];`

## Secrets Management

Use `ragenix` (agenix) for secret encryption:

```nix
{
  age.secrets.my-secret = {
    file = ../../secrets/creds/my-secret.age;  # Relative path
    owner = "alex";
    group = "users";
    path = "/home/alex/.config/my-app/config";
  };
}
```

- Store encrypted secrets in `secrets/` directory
- Reference secrets via `age.secrets.<name>.file` with relative paths
- Never commit unencrypted secrets
- Use `ragenix edit secrets/creds/my-secret.age` to edit

## Testing

No automated test suite. Test changes via:

1. `nix flake check` - Fast evaluation check
2. `nh os build` - Build without switching (current machine)
3. `nixos-rebuild build --flake .#<hostname>` - Build specific machine
4. Deploy to non-critical hosts first

**Important:** Nix reads current version of files from disk but ignores files that git doesn't know about. Run `git add -A` (or `git add <new-files>`) when you've created **new** files that need to be tracked by git. Modified files don't need to be staged.

## CI/CD

GitHub Actions workflows:
- `.github/workflows/fmt.yml` - Checks nixfmt formatting
- `.github/workflows/update.yml` - Automated flake.lock updates

## Git Conventions

- Commit lock file updates with: `nix flake update --commit-lock-file`
- Format code with `treefmt` before committing
- CI checks formatting on all PRs and pushes

## Common Pitfalls

1. **Missing imports**: When moving files, ensure all imports are updated. For example, shell/default.nix must import all shell modules.

2. **Git state**: Nix reads files from disk but ignores files that git doesn't know about. Run `git add -A` only when you've created **new** files that need to be tracked by git. Modified files don't need to be staged.

3. **Path references**: After moving files, update relative paths in `file = ...` attributes.

4. **Role composition**: The hierarchy is: `core` → `desktop`/`server`/`family`. Don't import `core` directly in machines, import the appropriate role.

5. **Secrets paths**: Always use relative paths like `../../secrets/creds/...` not absolute paths.

## Adding New Functionality

### Adding a new machine
1. Create `machines/<hostname>/` directory
2. Add `default.nix`, `hardware.nix`, `mounts.nix`, `system.txt`
3. Import appropriate role (`roles/desktop`, `roles/server.nix`, etc.)
4. Add hardware-specific profiles as needed

### Adding a new profile
1. Determine if it's role-specific or general reusable
2. Place in `profiles/<name>.nix` or `roles/<role>/<name>.nix`
3. Use relative paths for any file references
4. Import in appropriate role or machine config

### Adding a new service to whale
1. Create `profiles/server/<service>.nix`
2. Import in `machines/whale/default.nix` with `../../profiles/server/<service>.nix`
3. Follow existing patterns for secrets, networking, etc.
