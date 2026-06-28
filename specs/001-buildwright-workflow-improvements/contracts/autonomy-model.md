# Contract: Single autonomy behaviour & auto-continue

Backs `steering/autonomy.md`. Covers US4 (FR-007/008/009) and US6
(FR-013/014/015).

## Single behaviour (all commands)

Every command follows one autonomy behaviour (data-model §3): execute
autonomously; **pause** only when a decision is genuinely the human's to make (or
on ambiguity/low confidence); **stop** when genuinely blocked. No
environment-variable flag participates.

## Auto-continue (default)

- When a sequence of ready, question-free items exists (e.g. unchecked plan
  items), the workflow **MUST** advance through them without a manual re-invoke
  per item, using the host's native task tracking to make the queue visible.
- It **MUST** pause and surface the question on any genuine decision/approval/
  ambiguity, and **MUST** stop when blocked.
- The developer **MUST** be able to interrupt and pause/stop the sequence at any
  point (host-native interrupt honoured; explicit "stop"/"pause" respected).

## Flag retirement

- `BUILDWRIGHT_AUTO_APPROVE` **MUST NOT** appear in any canonical command,
  steering doc, `AGENTS.md`, or the constitution.
- The constitution's Principle I wording **MUST** be reconciled to this flagless
  model (FR-015).

**Acceptance**: repo-wide search for the flag in canonical sources + root docs →
zero matches (enforced by `validate-no-auto-approve.sh`).
