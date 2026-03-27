# DEV ROLE KNOWLEDGE BASE

## OVERVIEW

`roles/dev/` configures editor, tooling, and AI environments for desktop machines; imported automatically by `roles/desktop`.

## WHERE TO LOOK

| Need | File |
|------|------|
| Package list, overlays, dev session vars | `default.nix` |
| VS Code extensions and settings | `vscode.nix` |
| Zed editor config | `zed.nix` |
| OpenCode AI tool config | `opencode.nix` |
| Claude Code config | `claudecode.nix` |
| Codex CLI config | `codex.nix` |
| MCP server definitions | `mcp.nix` |
| Python env builder | `python.nix` |
| Docker credential helper | `docker.nix` |
| Jupyter nbconvert | `nbconvert.nix` |

## CONVENTIONS

- Overlays for custom input packages (`gastown`, `beads`, `dolt`) are defined in `default.nix`, not in a separate overlay file.
- Packages go in `hm.home.packages` in `default.nix`; tools with HM module config or substantial setup get their own file.
- AI/editor tools each get a dedicated file (`opencode.nix`, `claudecode.nix`, `codex.nix`, `mcp.nix`, `vscode.nix`, `zed.nix`).
- `python.nix` is a function `pkgs -> derivation`, not a standard NixOS module; it is called from `default.nix`.
- Dev session variables (`CARGO_TARGET_DIR`, `MYPY_CACHE_DIR`, etc.) are set via `hm.home.sessionVariables`.
- Build artifact caches go in `persist.cache.homeDirs`.
- `opencode-rules.md` is a static rules file loaded by the OpenCode tool; it is not a Nix module.

## ANTI-PATTERNS

- Do not add editor/AI tools to `roles/core/shell/`; those belong here.
- Commented-out packages (`devcontainer`, `antigravity`) are intentional history; do not auto-uncomment.
