# Environment
- We run NixOS
- Install tools: `nix profile add nixpkgs#<pkg>` (persistent) or `nix-shell -p <pkg> --run '<cmd>'` (one-off)
- Prefer profile if the tool will be needed again
- Projects follow `~/projects/<owner>/<name>` layout; use `origin` and `upstream` remotes for forks

# Planning
- If awaiting ANY user interaction, you MUST use the question tool instead of asking in plain chat. Todo continuation will force the run to continue if you stop with unfinished todo items and no explicit question-tool block on user input
- Feel free to ask clarifying questions about requirements and architecture, but use the question tool whenever you need user input
- Do not rely on hidden thinking for important information; record important conclusions, decisions, and key ideas in chat messages intended for users to review; otherwise, normal thinking tokens can be lost between messages
- For requests with many edits or a large scope, first split the work into small atomic tasks, create or update a todo list, and execute from that list
- Keep the todo list accurate at all times: unfinished todo items trigger forced continuation, so mark completed tasks immediately, add newly discovered tasks, and never leave stale entries behind
- If you believe the work is finished, mark every completed todo item as completed before stopping. Do not leave finished work marked as pending or in_progress, or todo continuation will treat the run as unfinished and force more work
- If the repo starts clean, create atomic commit for each atomic task just after task completion
- Deviate from the plan when better solutions or suitable API contracts emerge — record the reason and update spec/plan instantly
- Do NOT use git worktrees unless explicitly requested

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
- Never restate what the code does
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

## Rust
- **Errors**: `Result`/`Option` for normal conditions (IO, parsing, network, user input); panics only for bug-indicating invariant violations
- **Libraries**: `thiserror` for typed error enums; avoid `anyhow` (callers need concrete types)
- **CLI tools**: `color-eyre` with `eyre::Result`
- **Propagation**: use `?`; avoid `.unwrap()` unless the invariant is trivially obvious
- **Ownership**: prefer `&T` over `.clone()` unless necessary; understand the cost of allocation
- **Idioms**: `match` for control flow, iterators for sequences, `From`/`Into` for conversions
- **Constants**: consider `#[repr(...)]` enum over separate `const` values for related groups
- **Enums**: use `#[non_exhaustive]` only when variants genuinely will grow; when a variant accumulates 3+ fields, extract a dedicated struct — keeps the enum definition scannable and lets the struct have its own methods and `impl` blocks
- **Newtypes**: wrap for distinct units (meters vs feet), opaque handles, validated inputs (`Email`, `NonEmptyVec`); skip when every inner value is valid and no confusion risk
- **Serde + newtypes**: never `#[derive(Deserialize)]` on validated newtypes — it bypasses validation; use `#[serde(try_from = "...")]`
- **Numeric casts**: `From`/`Into` for widening, `try_from()`/`try_into()` for narrowing; bare `as` silently truncates
- **Async lifecycle**: track every `JoinHandle` for join or cancellation; fire-and-forget spawns hide panics and prevent graceful shutdown; long-lived handles should cancel their background task on `Drop`
- **`select!` safety**: verify every branch is cancellation-safe; if not, use a fused/pinned future or restructure to avoid data loss
- **Doc comments placement**: place doc comments (`///`, `/** */`) before attributes like `#[derive(...)]` on the item they document
- **Tooling**: must pass `cargo clippy` without warnings; format with `cargo fmt`

## Python
- **Typing**: modern annotations (`str | None`, `list[int]`); complete signatures on public functions
- **Tooling**: new projects use `ruff` + `uv` + `uv_build`; existing projects follow established toolchain
- **Structure**: `pyproject.toml` over `setup.py`/`setup.cfg`; pin deps in lock files

## TypeScript/JavaScript
- **Language**: always TypeScript for new projects; enable `strict` mode
- **Package manager**: `pnpm` for new projects; follow existing project's choice
- **Typing**: `unknown` over `any` with type guards; `interface` for object shapes (unless unions/mapped types needed); `as const` for literal tuples
- **Nullability**: enable `strictNullChecks`; use `?.` and `??` over manual checks
- **Async**: `async`/`await` over `.then()` chains; always handle rejections — never leave a floating promise
- **Imports**: ES modules; prefer named exports over default exports for better refactoring and IDE discoverability
- **Tooling**: `biome` for new projects; follow established toolchain otherwise; `tsx` for running TS scripts

## React
- Same sizing rules apply to components and hooks — extract sub-components/custom hooks at the same thresholds
- More than ~8 `useState` calls in one component → split into sub-components with own state, or use `useReducer`
- Use `useId()` for DOM IDs in reusable components — hardcoded IDs break with multiple instances
- Don't use `innerHTML` for content React can render — bypasses the virtual DOM and risks XSS
- Omitted effect dependencies require a comment explaining why the omission is safe when suppressing the lint rule
