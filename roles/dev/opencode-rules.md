# Environment
- We run NixOS
- Install tools: `nix profile add nixpkgs#<pkg>` (persistent) or `nix-shell -p <pkg> --run '<cmd>'` (one-off)
- Prefer profile if the tool will be needed again
- Projects follow `~/projects/<owner>/<name>` layout; use `origin` and `upstream` remotes for forks

# Planning
- Ask clarifying questions about requirements and architecture when needed
- For requests with many edits or a large scope, first split the work into small atomic tasks, create or update a todo list, and execute from that list
- Keep the todo list accurate at all times: unfinished todo items trigger forced continuation, so mark completed tasks immediately, add newly discovered tasks, and never leave stale entries behind
- If you believe the work is finished, mark every completed todo item as completed before stopping. Do not leave finished work marked as pending or in_progress, or todo continuation will treat the run as unfinished and force more work
- If the repo starts clean, create atomic commit for each atomic task just after task completion
- Deviate from the plan when better solutions or suitable API contracts emerge — record the reason and update spec/plan instantly
- Do NOT use git worktrees unless explicitly requested
- Always use `.agents/{specs,plans}` only instead of `docs/superpowers` (keep using `.sisyphus` or other dirs if asked to) for specs and plans, never commit them

# Git
- If the repo already has multiple uncommitted changes, do not create commits automatically unless explicitly requested
- Never push without explicit request
- Never add commit attribution trailers (Co-authored-by, etc.)

# Code Quality
These rules are not exhaustive — on code review, flag any issue you find, even if not listed here.

## Sizing & Separation
- One function — one job; extract at ~30 lines or when a section needs a "what" comment
- One file — one cohesive area; look for split boundaries at ~400 lines
- Guidelines, not hard limits — readability trumps line counts

## Error Handling
- Catch only with a concrete recovery strategy (retry, fallback, rollback, user message, cleanup)
- Keep try/catch scope narrow — large blocks mask unrelated failures
- Never swallow errors when the function fails its primary task (e.g. returning an empty placeholder on network failure)
- Empty catch blocks (`catch {}`, `.catch(() => {})`) must have a comment explaining why the error is safe to ignore; prefer `console.warn`/`tracing::warn!` for debuggability

## Comments
- Never just restate what the code does
- Explain **why**: non-obvious intent, business context, workaround reasons
- If code needs a "what" comment, clarify the code instead (better names, simpler structure)

## Abstraction & DRY
- Every indirection layer must earn its existence through reuse or meaningful simplification
- No wrappers, helpers, or layers used only once — inline them; if a helper just forwards arguments, inline it
- Two duplicates are a smell; three are a signal to extract (duplicated functions drift apart over time)
- Don't extract prematurely — single-use wrappers add indirection without value

## Dispatchers
- Large `match` with substantial arms → extract each arm into a handler; dispatcher only matches and delegates

## Literals
- Named constants or config for non-obvious values; repeated identifiers (event topics, endpoint URLs) defined once
- Shared visual tokens (colors, animation durations, breakpoints) defined once in a central place — don't scatter hex colors across files
- Acceptable inline: 0, 1, empty string, spec-defined constants (HTTP 404, standard ports), math constants

## Public API Docs
- Doc comments on public types, traits, and functions — explain **why** and **when**, not restate the name
- Focus on invariants, failure modes, non-obvious behavior
- Skip trivial docs (`pub struct User { pub name: String }` needs no "A user." comment)

## General
- Follow idiomatic standards; prefer stdlib/popular packages over reinventing
- Never guess dependency versions — verify via crates.io, npm, PyPI, or the relevant registry
- Prefer latest Rust edition; for C++ prefer latest mature standard with broad compiler support
- Prefer async I/O for network/disk/blocking; sync is fine for CPU-bound or trivial sequential work
- Every lint/compiler suppression (`eslint-disable`, `#[allow(...)]`, etc.) must include a short comment justifying why it is safe

## Python
- **Typing**: modern annotations (`str | None`, `list[int]`); complete signatures on public functions
- **Tooling**: new projects use `ruff` + `uv` + `uv_build`; existing projects follow established toolchain
- **Structure**: `pyproject.toml` over `setup.py`/`setup.cfg`; pin deps in lock files

## TypeScript/JavaScript
- **Language**: always TypeScript for new projects; enable `strict` mode
- **Package manager**: `pnpm` for new projects; follow existing project's choice
- **Typing**: `unknown` over `any` with type guards; `interface` for object shapes (unless unions/mapped types needed); `as const` for literal tuples
- **Nullability**: enable `strictNullChecks`; use `?.` and `??` over manual checks
- **Tooling**: `biome` for new projects; follow established toolchain otherwise; `tsx` for running TS scripts
