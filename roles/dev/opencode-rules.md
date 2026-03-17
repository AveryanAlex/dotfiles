# Environment
We run NixOS. To install a missing tool, use `nix profile add nixpkgs#<package>` for commonly used utilities
or `nix-shell -p <package> --run '<command>'` for one-off runs. Prefer adding to profile if the tool will be
needed again.

# Plan Writing Rules
Feel free to ask the user clarifying questions or questions about architecture.

# Plan Execution Rules
Do not follow the plan dogmatically if better solutions or suitable API contracts are discovered during
implementation. Any deviations from the plan must be recorded with a reason.
Do NOT use git worktrees unless the user explicitly requests them. Subagents frequently mishandle worktree state and context isolation.

# Code Quality

## Sizing & Separation
Each function should do one thing. If it exceeds ~30 lines or requires a comment explaining a section,
that section is a candidate for extraction. Files should stay under ~400 lines; if larger, look for cohesion
boundaries to split on. One file — one cohesive area. These are guidelines, not hard limits — readability
trumps line counts.

## Exception Handling
Catch only when you have a concrete recovery strategy (retry, fallback, rollback, user-visible message,
resource cleanup). Keep try/catch scope narrow — wrapping large blocks masks unrelated failures.
Do not swallow errors if the function fails its primary task. Bad pattern: returning an empty placeholder
on network failure instead of propagating the error.

## Comments
NEVER write comments that restate what the code does. Comments should explain **why** — non-obvious intent,
business context, or workaround reasons. If code needs a "what" comment to be understood, clarify the code
itself (better names, simpler structure) instead of annotating.

## No Premature Abstraction
Do not create wrapper functions, helper classes, or abstraction layers that are only used once. Every
indirection layer must earn its existence through actual reuse or meaningful simplification. If a "helper"
just forwards arguments to another function, inline it.

## DRY for Utilities
Two occurrences of the same logic are a smell; three are a clear signal to extract a shared utility.
Duplicated functions drift apart over time. But do not extract prematurely — a single-use wrapper adds
indirection without value.

## Match-Heavy Dispatchers
When a single function has a large `match` where each arm does substantial work, extract each arm into
a dedicated handler. The dispatcher should only match and delegate.

## Magic Numbers & String Literals
Use named constants or configuration for any non-obvious literal. Repeated string identifiers (event topics,
UUIDs, endpoint URLs) must be defined once and referenced by name. Acceptable inline: universal values
(0, 1, empty string), well-known protocol/spec-defined constants (HTTP 404, standard port numbers),
and mathematical constants.

## Public API Documentation
Public types, traits, and functions should have doc comments that explain **why** and **when**, not restate
the name. Focus on invariants, failure modes, and non-obvious behavior. Self-explanatory items
(e.g. `pub struct User { pub name: String }`) do not need a comment that just says "A user." —
skip trivial docs.

## Language Standards
Follow the idiomatic standards of the language you are using. Do not reinvent the wheel if functionality
already exists in the standard library or a popular package.
IMPORTANT: When adding dependencies, NEVER guess version numbers from memory — always verify the current
version via crates.io, npm, PyPI, or the relevant registry. Prefer the latest Rust edition. For C++,
prefer the latest mature standard with broad compiler support.
Prefer async I/O when the workload involves network, disk, or other blocking operations and the language/runtime
supports it. Sync code is fine for CPU-bound or trivially sequential tasks.

## Rust Specifics
- **Error Handling**:
  - Use `Result`/`Option` for any condition that can occur during normal operation (IO, parsing, network,
    user input, missing data).
  - Panics (`panic!`, `unreachable!`, `.unwrap()`, `.expect()`) are appropriate for invariant violations
    that indicate a bug in the code itself, not in the data.
  - In libraries, use `thiserror` for typed, structured error enums. Avoid `anyhow` — callers need
    concrete types to match on.
  - In CLI tools and scripts, use `color-eyre` with `eyre::Result` for exception-style ergonomics.
  - Propagate errors with `?`. Avoid `.unwrap()` unless the invariant is trivially obvious from context.
- **Ownership & Borrowing**: Prefer borrowing (`&T`) over cloning (`T.clone()`) unless necessary.
  Understand the cost of allocation.
- **Idioms**:
  - Use `match` for complex control flow, iterators for sequences, and `From`/`Into` for conversions.
  - When a group of related constants shares the same type, use a `#[repr(...)]` enum instead of
    separate `const` values.
  - Mark enums with `#[non_exhaustive]` only when variants are genuinely expected to grow.
- **Type Safety — Newtypes**:
  - **Do wrap**: values with distinct physical units (meters vs feet), opaque handles/indices, and
    validated inputs where the newtype enforces an invariant at construction (e.g. `Email`, `NonEmptyVec`).
  - **Don't wrap**: when every value of the inner type is valid and there's no realistic confusion risk.
    If you'd provide unchecked `From` in both directions, the newtype adds noise without safety.
  - **Serde caveat**: never `#[derive(Deserialize)]` on a validated newtype — it bypasses validation.
    Use `#[serde(try_from = "...")]` or a custom impl.
- **Numeric Casts**: Avoid bare `as` for numeric conversions. Use `From`/`Into` for lossless widening,
  and `try_into()`/`try_from()` for narrowing or cross-sign casts. Bare `as` silently truncates/saturates.
- **Async Task Lifecycle**:
  - Every `tokio::spawn` must have its `JoinHandle` tracked for join or cancellation. Fire-and-forget
    spawns hide panics and prevent graceful shutdown. Long-lived operation handles should cancel their
    background task on `Drop`.
  - Never hold a sync `Mutex`/`RwLock` guard across an `.await` — it blocks the executor thread.
    Use `tokio::sync` locks or restructure to drop the guard before awaiting.
  - In `select!` loops, verify that every branch operation is cancellation-safe. If it isn't, use
    a fused/pinned future or restructure to avoid data loss on cancellation.
- **Tooling**: Code must pass `cargo clippy` without warnings. Format with `cargo fmt`.

## Python Specifics
- **Typing**: Use modern type annotations (`str | None` not `Optional[str]`, `list[int]` not `List[int]`).
  All public functions must have complete type signatures.
- **Tooling**: For new projects, use `ruff` for linting and formatting, `uv` as the package manager,
  and `uv_build` as the build backend. In existing projects, follow the established toolchain.
- **Project Structure**: Prefer `pyproject.toml` over `setup.py`/`setup.cfg`. Pin dependencies in lock files.
