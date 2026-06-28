# Contract: `/bw-ship` failure handling via context inference

Covers US6 (FR-016/017) and the `bw-ship` part of flag removal (FR-013/014).

## Replaces

The current `bw-ship.md` "Failure Handling" section's two flag-gated modes
(`Interactive Mode (BUILDWRIGHT_AUTO_APPROVE=false)` /
`Autonomous Mode (BUILDWRIGHT_AUTO_APPROVE=true)`).

## Behaviour

On a step failing after retries, infer execution context (see
data-model §4):

- **interactive** (TTY attached, no CI signal): pause and show the existing
  `SHIP BLOCKED` panel with failed step, reason, and remediation; wait for the
  human.
- **unattended** (`CI`/`GITHUB_ACTIONS` set, or no TTY): preserve completed work
  — stage & commit to the feature branch, push, create a `[FAILED]`-prefixed PR
  using the failure-summary template, exit non-zero.
- **indeterminate**: default to **unattended** (never hang).

## Constraints

- **MUST** rely only on host/environment signals (TTY, CI vars), **not** any
  Buildwright-specific configuration (FR-017).
- **MUST NOT** reference `BUILDWRIGHT_AUTO_APPROVE`.

**Acceptance** (maps to US6):
- `grep BUILDWRIGHT_AUTO_APPROVE bw-ship.md` → no matches.
- Simulated CI failure produces a `[FAILED]` PR + non-zero exit; interactive
  failure shows the panel and waits.
