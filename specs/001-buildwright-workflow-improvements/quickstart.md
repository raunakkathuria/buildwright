# Quickstart: Validating Buildwright Workflow Improvements

How to prove the feature works end-to-end. Run from the repo root. Detailed
behaviour lives in [contracts/](./contracts/) and [spec.md](./spec.md); this is
the run/validation guide.

## Prerequisites

- Repo cloned; `make` available; at least one host agent CLI (Claude Code is the
  primary validation host).
- Changes made in `.buildwright/` and propagated: `make sync` has been run.

## Gate checks (automated — Constitution Principle III)

```bash
make sync-check          # canonical .buildwright/ matches generated dirs
make validate            # doc coverage + new flag-absence gate
scripts/validate-no-auto-approve.sh   # NEW: must exit 0 (no flag references)
```

Expected: all exit 0. `validate-no-auto-approve.sh` is the Red→Green anchor —
it FAILS before the flag is removed and PASSES after.

## Per-story validation

### US6 — flag retired (FR-013/015)
```bash
grep -rn "BUILDWRIGHT_AUTO_APPROVE" .buildwright AGENTS.md .specify/memory/constitution.md
```
Expected: **no matches**. Each of `bw-work`, `bw-ship`, `bw-plan`, `bw-analyse`
documents one autonomy behaviour with no flag branch.

### US1 — `/bw-plan` writes reliably (FR-001/002)
- Run `/bw-plan "small planning question"` several times, at low and high context.
  Expected: `plan.md` written on first attempt each time; no "writing now" stall.
- Point `output_dir` at an unwritable path. Expected: a clear error + recovery
  note, **not** a hang.

### US2 — faithful handoff (FR-003/004)
- Complete a `/bw-plan`, then continue into implementation. Expected: the real
  `/bw-work` runs (same steps/gates as typing `/bw-work`); no free-text
  "proceed?" prompt; never run from memory. On a host without faithful invocation,
  expected: explicit "run `/bw-work`" instruction.

### US3 — native capabilities (FR-005/006, SC-004)
- Audit `bw-*` against `steering/native-capabilities.md`. Expected: zero cases of
  prose-reimplementing a native capability that exists/fits; every capability has
  a documented fallback.

### US4 — auto-continue default (FR-007/008/009)
- Give a plan with several question-free ready items; start once. Expected: it
  advances through them with no per-item re-invoke, pauses on a genuine decision,
  and can be interrupted/stopped.

### US5 — findings capture (FR-010/011)
- During a `bw-work`/`bw-ship` run, defer a decision and discover an
  upstream-worthy issue. Expected: both recorded in the standard format
  (data-model §1) in one known, discoverable location.

### bw-ship failure inference (FR-016/017)
```bash
CI=true   # simulate unattended
```
- Force a failing gate. Expected (unattended): completed work preserved, `[FAILED]`
  PR created, non-zero exit. In an interactive TTY with no CI signal: the
  `SHIP BLOCKED` panel shows and waits.

## Definition of done

- All gate checks pass; every per-story check meets its expected outcome;
  `CHANGELOG`, `README`, `AGENTS.md`, and the constitution reflect the changes.
