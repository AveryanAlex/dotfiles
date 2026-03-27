# DESKTOP ROLE KNOWLEDGE BASE

## OVERVIEW

`roles/desktop/` is the full desktop stack; it imports `roles/core` and `roles/dev` automatically.

## WHERE TO LOOK

| Need | File |
|------|------|
| Desktop composition, system packages, tproxy/xray | `default.nix` |
| Window manager / compositor (niri) | `shell/niri.nix` |
| Shell material theme (DMS) | `shell/dms.nix` |
| Desktop shell composition | `shell/default.nix` |
| Terminal emulators | `apps/wezterm.nix`, `apps/alacritty.nix` |
| Browser config | `apps/firefox.nix` |
| Catch-all GUI apps (package-only) | `apps/misc-a.nix` |
| Media player | `apps/mpv.nix` |
| Desktop tuning | `tuning.nix` |
| Distrobox / container dev envs | `distrobox.nix` |
| Tank storage mount helper | `tank.nix` |
| Flatpak deploy-at-activation | `deployapp.nix` |
| NixOS compatibility shims | `compat.nix` |
| Games | `games/minecraft.nix`, `games/xonotic.nix` |

## CONVENTIONS

- `default.nix` sets `nixcfg.desktop = true` to signal desktop mode to the nixcfg module.
- `default.nix` imports many profiles from `../../profiles/` (fonts, mail, music, sdr, flatpak, sync, etc.); check its import list before adding a new profile import.
- Transparent proxy is enabled at the desktop layer: `networking.tproxy.output.enable = true` with xray backend.
- `programs.nh.flake` points to `/home/alex/projects/AveryanAlex/dotfiles`.
- Boot params include zswap and `boot.binfmt.emulatedSystems = ["aarch64-linux"]` for cross-compilation.
- New GUI apps with a HM module get a dedicated file under `apps/`; package-only apps go in `apps/misc-a.nix`.
- New shell/compositor modules go under `shell/` and are imported from `shell/default.nix`.

## ANTI-PATTERNS

- Do not import `roles/dev` from machine configs; desktop already includes it.
- Do not uncomment `waydroid.nix` or `opensnitch.nix` without testing; they are disabled intentionally.
