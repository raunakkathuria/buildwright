# Contract: Deferred-findings capture convention

Backs `steering/findings.md`. Covers US5 (FR-010/011).

## Scope

Buildwright owns the **convention and format**; it does NOT seed files into any
consuming service template (out of scope).

## Two classes (data-model §1)

- **report-upstream**: an issue better fixed at its source so others benefit.
- **before-production**: a decision acceptable for staging/demo that must be
  resolved before a production release.

## Behaviour

- `bw-work` and `bw-ship` **MUST** reference this convention so a finding is
  recorded in the standard format **at the moment it arises**, into one known,
  discoverable location per class.
- The record **MUST** follow the field set in data-model §1 for its class.
- If no target file exists yet, the finding **MUST** still be recorded somewhere
  discoverable (e.g. created on first use), not discarded (spec edge case).

## v1 simplicity

- No dedicated capture command in v1 (YAGNI). The convention + format in steering,
  referenced by the workflow commands, is sufficient. A `/bw-*` capture command is
  a future option if the convention proves insufficient.

**Acceptance** (maps to US5/SC-005): a deferral made during `bw-work`/`bw-ship` is
written in the standard format to the known location; both classes are findable in
one place.
