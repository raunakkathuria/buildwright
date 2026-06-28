# Implementation Plan: Buildwright Workflow Improvements

**Branch**: `001-buildwright-workflow-improvements` | **Date**: 2026-06-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-buildwright-workflow-improvements/spec.md`

## Summary

Improve the Buildwright command set based on developer feedback, with one
cross-cutting lever: **lean on the host agent tool's native capabilities instead
of reimplementing them in prose.** The work fixes the `/bw-plan` plan-write stall
(US1), makes the plan→work handoff faithful (US2), standardises on native
capabilities with graceful fallback (US3), makes autonomous auto-continue the
default (US4), adds a consistent deferred-findings convention (US5), and retires
the unenforced/overloaded `BUILDWRIGHT_AUTO_APPROVE` flag in favour of a single
autonomy behaviour (US6).

All changes are edits to the **canonical, tool-agnostic** `.buildwright/`
configuration plus `AGENTS.md`, the constitution, and validation scripts, then
propagated to per-tool directories via `make sync`. There is no application
runtime — the "product" is command/steering markdown and the shell tooling that
syncs and validates it.

## Technical Context

**Language/Version**: Markdown (command/steering definitions) + Bash (sync,
validation, hooks). No compiled runtime.

**Primary Dependencies**: `make` (orchestration: `sync`, `sync-check`,
`validate`), `scripts/sync-agents.sh` (canonical → per-tool generation),
`scripts/validate-docs.sh` / `validate-skill.sh` (gates). Host agent tools
consuming the output: Claude Code, Codex, OpenCode, Cursor.

**Storage**: N/A (files in git). No database, no persistent runtime state.

**Testing**: Shell validation gates — `make sync-check` (canonical vs generated
parity), `scripts/validate-docs.sh` (command/doc coverage), `validate-skill.sh`,
plus a new flag-absence check (`BUILDWRIGHT_AUTO_APPROVE` must not appear).
Prose-behaviour outcomes (e.g. the agent no longer stalls) are validated
empirically per the spec's per-story Independent Tests, not by unit tests.

**Target Platform**: Developer machines and CI running the four host agent CLIs
on macOS/Linux.

**Project Type**: Agent-workflow configuration framework (markdown commands +
shell scripts), multi-target via `make sync`. Single repository.

**Performance Goals**: N/A (authoring tool; no runtime perf target). The
relevant qualitative goal is reduced token waste from not reimplementing native
behaviour (US3) — not separately measured here.

**Constraints**:
- `.buildwright/` and `AGENTS.md` are canonical/committed; `.claude/`,
  `.opencode/`, `.cursor/` are generated and MUST NOT be hand-edited (FR-012).
- `.buildwright/` is **tool-agnostic**: per-host native-capability differences
  must be expressed without coupling the canonical source to one tool.
- After any `.buildwright/` edit, `make sync` must run before commit.

**Scale/Scope**: 5 command files, ~2 steering docs (1 new), `AGENTS.md`, the
constitution, 1 new validation script. No new third-party dependencies.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify the plan against `.specify/memory/constitution.md` (v1.0.0):

- [x] **I. Agent-First Autonomy**: The feature strengthens this principle —
      auto-continue as default (US4) and a single autonomy behaviour (US6) are
      direct expressions of "execute autonomously, pause only on genuine
      decisions, stop when blocked." Context-inference (FR-016) preserves the
      unattended-CI value without a manual flag.
- [x] **II. Test-First (NON-NEGOTIABLE)**: For the *verifiable* changes, tests
      precede the change — the `BUILDWRIGHT_AUTO_APPROVE` flag-absence check and
      `make sync-check` parity are written/expected to FAIL first (flag still
      present, sync stale), then pass after edits. Prose-behaviour changes that
      cannot be unit-tested (stall recovery, faithful handoff) are covered by the
      spec's Independent Tests and the quickstart validation guide; this nuance
      is recorded honestly rather than claiming false unit coverage.
- [x] **III. Verification Before Commit**: Gates identified — `make sync-check`,
      `make validate`, `scripts/validate-docs.sh`, `validate-skill.sh`, and the
      new flag-absence check. No typecheck/build apply (no compiled code) — noted
      as SKIP with reason.
- [x] **IV. Documentation Is Part of Done**: The command/steering markdown *is*
      the documentation; `AGENTS.md`, `README.md`, `CHANGELOG`, and the
      constitution are updated in the same work item (FR-013/FR-015).
- [x] **V. Simplicity & Boring Technology**: Net simplification — removes an
      unenforced, overloaded flag (US6) and deletes hand-rolled equivalents of
      native behaviour (US3). The one added artifact (a native-capabilities
      steering doc) is the *mechanism* for US3, not speculative; justified below.

**Result**: PASS. No violations. Complexity Tracking left empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-buildwright-workflow-improvements/
├── plan.md                         # This file (/speckit-plan output)
├── spec.md                         # Feature spec (/speckit-specify + /speckit-clarify)
├── research.md                     # Phase 0 output (this command)
├── research-native-capabilities.md # Prior host-capability survey (referenced by research.md)
├── data-model.md                   # Phase 1 output — conceptual schemas (no DB)
├── quickstart.md                   # Phase 1 output — validation guide
├── contracts/                      # Phase 1 output — command/behaviour contracts
│   ├── bw-plan.behaviour.md
│   ├── bw-ship.failure.md
│   ├── autonomy-model.md
│   ├── native-capabilities.md
│   └── findings-capture.md
└── checklists/requirements.md      # Spec quality checklist
```

### Source Code (repository root)

```text
.buildwright/                  # CANONICAL, tool-agnostic source (edited here)
├── commands/
│   ├── bw-plan.md             # US1 (plan-write), US2 (handoff), US6 (flag removal)
│   ├── bw-work.md             # US2 (handoff target), US5 (findings), US6
│   ├── bw-ship.md             # US6 (flag removal), FR-016/017 (context inference)
│   ├── bw-analyse.md          # US6 (flag removal)
│   └── bw-verify.md           # (review for native-capability alignment)
├── steering/
│   ├── philosophy.md          # (referenced; autonomy wording reconciled)
│   ├── autonomy.md            # NEW — single autonomy behaviour + auto-continue (US4/US6)
│   ├── native-capabilities.md # NEW — per-host capability map + fallback rule (US3)
│   └── findings.md            # NEW — deferred-findings convention + format (US5)
└── agents/                    # (unchanged unless audit finds prose-reimplementation)

AGENTS.md                      # Canonical agent instructions — flag removal (US6/FR-013)
CLAUDE.md                      # Pointer stub + SPECKIT plan reference (updated this phase)
.specify/memory/constitution.md# Governance — reconcile autonomy principle (FR-015)
scripts/
├── sync-agents.sh            # (unchanged mechanism; regenerates per-tool dirs)
├── validate-docs.sh          # (pattern reference)
└── validate-no-auto-approve.sh # NEW — gate: flag absent from canonical + docs (US6)
Makefile                       # wire the new gate into `make validate`

# GENERATED (never hand-edited; produced by `make sync`):
.claude/  .opencode/  .cursor/rules/   dist/buildwright/
```

**Structure Decision**: Single repository, edit-canonical-then-sync. All
behaviour changes land in `.buildwright/` (+ root `AGENTS.md`, constitution).
Per-host native-capability differences are expressed in a new tool-agnostic
steering doc (`native-capabilities.md`) that maps a capability to each host's
equivalent and states the "prefer native, else documented fallback" rule —
keeping the canonical source tool-agnostic while satisfying US3/FR-005/FR-006.
New behaviour shared across commands (autonomy model, findings convention) lives
in steering docs rather than being duplicated per command (DRY).

## Complexity Tracking

> No constitution violations. Section intentionally empty.
