# AGENTS.md

Instructions for AI coding agents working on this NixOS configuration repository.

## Overview

This is a NixOS system configuration using flakes. It defines multiple machines (whale, lizard, alligator, etc.) with shared profiles, modules, and roles.

## Commands

### Build/Deploy
- `nixos-rebuild switch --flake .#<hostname>` - Deploy to local machine
- `nixos-rebuild build --flake .#<hostname>` - Build without switching
- `nix flake check` - Evaluate flake for errors
- `nix flake update --commit-lock-file` - Update all inputs and commit lock file

### Formatting
- `nixfmt -c .` - Check formatting
- `nixfmt .` - Auto-format all .nix files
- `nix run nixpkgs#nixfmt -- -c .` - Run formatter without installing

### Development
- `direnv allow` - Load dev shell (auto-loads with `use flake`)
- `colmena apply` - Deploy to remote hosts via colmena

## Code Style

### Nix Formatting
- Use **nixfmt** formatter (enforced in CI via `.github/workflows/fmt.yml`)
- Trailing newline at end of files
- No trailing whitespace

### Module Structure
Modules follow the standard NixOS module format:

```nix
{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.namespace.optionName;
in
{
  options = {
    namespace.optionName = {
      enable = mkEnableOption "description";
      # other options...
    };
  };

  config = mkIf cfg.enable {
    # configuration...
  };
}
```

### Imports and Dependencies
- Use relative paths for local imports: `../../profiles/shell.nix`
- Use `inputs.self.nixosModules` for self-referencing modules
- Prefer `with lib;` for common functions (mkOption, types, mkIf, etc.)
- List imports one per line for readability

### Naming Conventions
- Module files: lowercase-with-dashes.nix (e.g., `nebula-averyan.nix`)
- Option namespaces: lowercase (e.g., `networking.nebula-averyan`)
- Variable names: camelCase for Nix expressions
- Machine directories: lowercase (e.g., `alligator/`, `whale/`)

### File Organization
- `machines/<hostname>/` - Machine-specific configurations
  - `default.nix` - Main machine config
  - `hardware.nix` - Hardware-specific settings
  - `mounts.nix` - Filesystem mounts
  - `system.txt` - System architecture (e.g., "x86_64-linux")
- `profiles/` - Reusable configuration units (bluetooth, shell, etc.)
- `modules/` - Custom NixOS modules with options
- `roles/` - High-level role definitions (desktop, server, minimal)
- `hardware/` - Hardware-specific modules

### Secrets Management
- Use `ragenix` (agenix) for secret encryption
- Store encrypted secrets in `secrets/` directory
- Reference secrets via `age.secrets.<name>.file`
- Never commit unencrypted secrets

### State Management
- Use `persist.state.files` and `persist.state.directories` for impermanence
- Mark machine-specific state in profiles/persist*.nix

### Git Conventions
- Commit lock file updates with: `nix flake update --commit-lock-file`
- CI checks formatting on all PRs and pushes

## Testing

No automated test suite. Testing is done via:
1. `nix flake check` - Evaluates all configurations
2. `nixos-rebuild build --flake .#<hostname>` - Build without deploying
3. Deploy to non-critical hosts first

## CI/CD

GitHub Actions workflows:
- `.github/workflows/fmt.yml` - Checks nixfmt formatting
- `.github/workflows/update.yml` - Automated flake.lock updates

## Common Patterns

### Adding a new machine
1. Create `machines/<hostname>/` directory
2. Add `system.txt` with architecture
3. Create `default.nix`, `hardware.nix` (import from nixos-hardware if available)
4. Import relevant profiles and roles
5. Test with `nixos-rebuild build --flake .#<hostname>`

### Adding a profile
1. Create file in `profiles/` or subdirectory
2. Use standard module structure if providing options
3. Import in machine or role files as needed

### Using home-manager
- Available via `inputs.home-manager`
- Configure via `home-manager.users.<username>` in machine configs
- Custom `hm` alias used throughout for home-manager options
