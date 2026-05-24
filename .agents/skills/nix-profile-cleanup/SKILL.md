---
name: nix-profile-cleanup
description: Use when migrating packages from `nix profile list` into this dotfiles repo, especially when some packages are already declaratively managed and local profile entries must only be removed after a verified build.
---

# Nix Profile Cleanup

## Overview

This repo wants packages managed declaratively. The safe order is:

1. inventory the current profile,
2. trace the current host's import chain,
3. classify each package,
4. edit the reachable Nix files,
5. verify the host build,
6. only then clean the local profile.

Never remove profile packages first.

## When to Use

- A user wants to move imperatively installed packages into this repo.
- `nix profile list` shows tools that should live in `roles/`, `profiles/`, or `machines/`.
- Some packages may already be managed here, and you need to avoid duplicates.
- The user wants a smaller or empty local profile after migration.

Do not use this for throwaway packages the user does not want in dotfiles.

## Safety Rules

1. Save the full `nix profile list` output before changing anything.
2. Never edit `archive/`.
3. Never guess that `Name:` or a store-path suffix maps cleanly to `pkgs.<name>`.
4. Never treat a commented-out package as already managed.
5. Never auto-uncomment a commented-out package.
6. Never remove profile packages until the declarative edits build successfully.
7. If the user wants to remove everything, prefer `nix profile remove --all` after verification rather than removing shifting numeric indices one by one.
8. When editing an existing file, match that file's accessor and comment style.

## Host Reachability Check

Before routing packages, determine what the current machine actually imports.

1. Run `hostname`.
2. Read `machines/<host>/default.nix`.
3. Follow imports until you know whether the host reaches:
   - `roles/core`
   - `roles/dev`
   - `roles/desktop`
   - specific `profiles/*.nix`
4. Only place packages in files reachable from that host.

Important repo facts:

- `roles/desktop` already imports `../dev`; do not add `roles/dev` directly to machine configs unless there is a real exception.
- New files in `roles/`, `profiles/`, and `apps/` still need explicit imports.
- `hm` is available in this repo, but older files still use `home-manager.users.alex`; match the target file's style.
- Package placement rules live in the repo `AGENTS.md`; use that shared routing guidance instead of inventing a new destination.

## Inventory and Classification

1. Run `nix profile list` and keep the full output for rollback.
2. Normalize packages from the `Name:` field first.
3. Search `roles/`, `profiles/`, `machines/`, and `modules/` for each package, excluding `archive/`.
4. Classify each package into one of these states:

| State | Meaning | Action |
|---|---|---|
| active | Already managed in live code or by `programs.*.enable` | Do not add it again; only mark it for later profile cleanup |
| commented | Present only as a commented-out line | Show the user the file and line; ask whether to re-enable it or keep it out |
| absent | No live declaration exists | Route it to the correct repo location |
| uncertain | Name or attribute mapping is unclear | Stop and confirm before editing |

Treat `programs.<tool>.enable = true` as active management even if the package is not listed in `home.packages`.

If a package comes from overlays, pinned channels, or unusual attribute names, confirm the attribute instead of guessing. Examples already present in this repo include `stable.ripgrep-all`, `gastown`, `beads`, and `dolt`.

## Migration Workflow

1. Build a per-package plan with:
   - package name,
   - state (`active`, `commented`, `absent`, `uncertain`),
   - proposed destination from the repo `AGENTS.md` package-placement guidance,
   - whether the package should become permanent dotfiles state or simply disappear from the local profile.
2. Present that plan before editing whenever packages are `commented`, `absent`, or `uncertain`.
3. For `active` packages, do not touch the repo unless the existing declaration is clearly wrong.
4. For `commented` packages, never auto-uncomment. Ask whether to re-enable the existing line, add a new live declaration elsewhere, or drop it.
5. For `absent` packages, make the smallest repo-consistent edit.
6. If you create a new file, import it from the correct parent file.
7. Match the local style of the file you edit:
   - existing file -> match its current accessor style (`hm`, `home-manager.users.alex`, etc.)
   - new file -> match nearby siblings in the same directory
8. Format and verify the result. Prefer:
   - `treefmt`
   - `nh os build`
   - or `nixos-rebuild build --flake .#<hostname>` when you need an explicit host build
9. Only after a successful build and explicit confirmation that any unmanaged packages may be dropped, remove the profile entries.
10. If the user wants a completely clean profile after migration, run `nix profile remove --all` last.

## Verification Gate Before Removal

Do not clean the profile until all of these are true:

- the target files were edited in reachable modules,
- any new files were imported,
- the build succeeded for the current host,
- the user has seen the migration plan for non-trivial additions,
- you still have the original `nix profile list` output available for rollback.

## Common Mistakes

- Dumping every package into one file without checking whether it belongs in core, dev, desktop, a profile, or a machine file.
- Treating a commented-out package as already managed.
- Putting packages into `roles/dev/default.nix` on a host that does not import `roles/dev`.
- Guessing `pkgs.<name>` for packages with non-obvious attributes.
- Ignoring `programs.*.enable` declarations and adding duplicate package lines.
- Creating a new file and forgetting to import it.
- Removing packages from the profile before the build succeeds.

## Quick Checklist

- [ ] Saved `nix profile list`
- [ ] Traced `machines/<host>/default.nix` imports
- [ ] Classified every package as active, commented, absent, or uncertain
- [ ] Chosen destinations reachable from the current host
- [ ] Matched target-file style
- [ ] Imported any new files
- [ ] Verified the host build
- [ ] Removed the local profile entries only after verification
