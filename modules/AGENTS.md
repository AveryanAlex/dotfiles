# MODULES KNOWLEDGE BASE

## OVERVIEW

`modules/` contains custom NixOS modules auto-exported by `flake.nix` as `inputs.self.nixosModules.modules.*`.
Core currently imports `persist`, `nebula-averyan`, `tproxy`, and `xray`; `mihomo` exists as an alternative backend.

## WHERE TO LOOK

| Need | File |
|------|------|
| Impermanence wrapper and persistence tiers | `persist.nix` |
| Transparent-proxy plumbing | `tproxy.nix` |
| Xray backend | `xray.nix` |
| Mihomo backend | `mihomo.nix` |
| Nebula mesh options | `nebula-averyan.nix` |

## CONVENTIONS

- Module files use `with lib;` at top level and keep their option namespace aligned with the final NixOS path (`persist.*`, `networking.tproxy.*`, `services.xray-tproxy.*`, ...).
- `enable` flags use `mkEnableOption`; the main config block is gated with `mkIf cfg.enable`.
- When a default mirrors another module option, follow the existing `config.<other>.option or <fallback>` pattern and pair it with `defaultText = literalExpression "..."`.
- New files in `modules/` are auto-discovered by `flake.nix`; do not add manual flake output wiring for them.
- Static service UIDs/GIDs defined here must not collide with values used in `profiles/server/`.

## COUPLING

- `networking.tproxy` provides nftables/TProxy plumbing.
- `services.xray-tproxy` and `services.mihomo-tproxy` are backends that follow the tproxy port/mark defaults.
- `roles/core/default.nix` imports `tproxy` and `xray` together; changes here often require reading `roles/core/AGENTS.md` too.
- `persist.nix` is the repo-specific wrapper around impermanence; many profile and machine rules depend on its `state` / `derivative` / `cache` split.

## ANTI-PATTERNS

- Do not invent repo-specific option namespaces outside the actual NixOS path hierarchy.
- Do not manually register modules in `flake.nix`; discovery already happens automatically.
- Do not enable both proxy backends blindly; check how the target machine is wired first.
