# Contract: `/bw-plan` plan-write & handoff behaviour

Covers US1 (FR-001/002) and the `/bw-plan` side of US2 (FR-003).

## Plan write (Phase 5)

- **MUST** write the deliverable using the host's native file-write capability in
  a single decisive action per file, creating `output_dir` first if absent.
- **MUST NOT** emit a separate "writing now…" narration step before writing.
- **MUST** write incrementally (create then append) for large deliverables rather
  than buffering one large document.
- On write failure **MUST** report the specific cause (path, permission, etc.) and
  a recovery action, then STOP. **MUST NOT** retry silently or loop.

**Acceptance** (maps to US1):
- Repeated `/bw-plan` runs across context sizes persist `plan.md` on first attempt,
  no stall (empirical, quickstart).
- A write to an unwritable path yields a clear error, not a hang.

## Plan→work boundary

- On completion, **MUST NOT** end with a free-text "Want me to proceed?" that a
  "yes" would satisfy from memory.
- When continuing into implementation, **MUST** invoke the real `/bw-work` via the
  host's native command invocation; where unavailable, **MUST** direct the user to
  run `/bw-work`.
- **MUST NOT** run implementation from a recalled paraphrase of `/bw-work`.

## Flag removal

- **MUST NOT** reference `BUILDWRIGHT_AUTO_APPROVE` (Phase 2 "Clarify" rewritten to
  the single autonomy behaviour: apply sensible defaults autonomously; pause only
  on a genuinely human decision).
