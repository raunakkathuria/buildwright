# Phase 0 Research: Buildwright Workflow Improvements

Consolidated decisions. Host-capability facts come from
[research-native-capabilities.md](./research-native-capabilities.md) (surveyed
mid-2026); this file records the *design decisions* that resolve the spec's
open technical questions.

---

## D1 — Root cause and fix for the `/bw-plan` plan-write stall (US1, FR-001/002)

**Decision**: Rewrite `bw-plan.md` Phase 5 ("Write Deliverable") to (a) write the
deliverable with the host's native file-write tool **immediately**, in a single
decisive action per file, (b) for large plans, write incrementally
(create-then-append) rather than composing one giant buffer, (c) **never** narrate
"writing now…" as a separate step before writing, and (d) on a write failure,
report the specific cause and a recovery action and STOP — never retry silently
in a loop.

**Rationale**: The current Phase 5 is bare prose ("Write artifact files to
output_dir"). The reported stall always occurs at the announce-then-write
boundary and is independent of context fullness — consistent with the agent
narrating intent and entering an unproductive state instead of issuing the write
tool call. Removing the narrate-then-write pattern and mandating a single
decisive native write removes the trigger. This is the concrete instance of the
US3 "prefer native capabilities" lever.

**Alternatives considered**:
- *Force host plan-mode (`ExitPlanMode`) for the deliverable* — rejected as the
  primary fix: plan mode is for approval gating, not for writing a file to a
  known path, and it is not uniformly invokable from inside a command across all
  four hosts. Kept as an optional enhancement, not a dependency.
- *Harness patch* — out of scope; the hosts are not ours to modify. We reduce
  likelihood and add deterministic recovery instead.

**Honesty note**: We cannot unit-test "the agent does not stall." The fix is
validated empirically (quickstart repeated-run check). FR-002's failure path *is*
checkable (a write to an unwritable path must produce a clear error, not a hang).

---

## D2 — Faithful plan→work handoff mechanism (US2, FR-003/004)

**Decision**: Define a shared "plan→work boundary" behaviour (in
`steering/autonomy.md`): when crossing into implementation, the workflow MUST
invoke the *real* `/bw-work` via the host's native command/skill invocation; where
the host cannot invoke a command faithfully, it MUST instead instruct the user to
run `/bw-work`. It MUST NOT paraphrase `/bw-work` from memory and MUST NOT end
`/bw-plan` with a free-text "Want me to proceed?" that a "yes" would satisfy from
memory.

**Per-host mechanism** (from the capability survey):
- Claude Code: native command/skill invocation re-injects the real command body
  (the `Skill`/slash-command mechanism) → faithful auto-continue available.
- Codex / OpenCode / Cursor: native command/skill invocation exists; where a host
  build cannot guarantee faithful re-injection, fall back to directing the user.

**Rationale**: Resolves the feedback-#3 divergence structurally — there is no
"from memory" path left. Aligns auto-continue (US4) with the handoff fix: they
are compatible precisely because the continuation runs the real command.

**Alternatives considered**:
- *Always hand back to the user* (Slack thread's original lean) — rejected per the
  US4=auto-continue clarification; kept only as the fallback when faithful native
  invocation is unavailable.
- *One confirmation checkpoint then flow* — rejected (Q3 answer A); adds a prompt
  without adding safety once invocation is faithful.

---

## D3 — Expressing "prefer native capabilities" from a tool-agnostic source (US3, FR-005/006)

**Decision**: Add `steering/native-capabilities.md` — a tool-agnostic doc that
(1) lists the capabilities Buildwright relies on (structured plan/file write,
native command invocation, task/todo tracking, sub-agents, hooks), (2) maps each
to its per-host equivalent, and (3) states the rule: *use the host's native
capability where it exists and fits; otherwise fall back to the documented prose
behaviour, never fail.* Commands reference capabilities **generically** (e.g.
"track multi-item progress using the host's native task tracking"); the steering
doc supplies the host mapping.

**Rationale**: Keeps `.buildwright/` tool-agnostic (a hard constraint) while
enabling native usage. One DRY source of capability mappings instead of
per-command, per-tool prose. `make sync` already rewrites paths per tool; no sync
changes are required for this approach.

**Alternatives considered**:
- *Inject per-tool guidance in `sync-agents.sh`* — rejected as premature
  complexity (YAGNI); a steering doc is simpler and host-readable.
- *Branch command text per tool* — rejected; violates the tool-agnostic
  constraint and duplicates content.

---

## D4 — Auto-continue as default + control (US4, FR-007/008/009)

**Decision**: Document auto-continue in `steering/autonomy.md` as the **default**:
advance through ready, question-free items using the host's native task tracking;
pause and ask on any genuine decision/approval/ambiguity; stop when blocked. The
developer can interrupt at any pause point and can stop the sequence (host-native
interrupt + an explicit "stop"/"pause" instruction honoured by the workflow).

**Rationale**: Direct expression of constitution Principle I; matches feedback #1.
Native task tracking gives a visible, interruptible queue rather than an in-prose
checklist.

**Alternatives considered**: flag-gated (rejected, Q1) and one-item-per-invoke
(rejected, Q1) — see spec Clarifications.

---

## D5 — `bw-ship` failure handling via context inference (US6, FR-016/017)

**Decision**: Replace `bw-ship.md`'s "Interactive Mode / Autonomous Mode" flag
branch with a single **context-inferred** behaviour: detect interactive vs
unattended from environment signals (`[ -t 0 ]`/`[ -t 1 ]` TTY check and common
CI variables such as `CI`, `GITHUB_ACTIONS`); interactive → pause and ask
(show the existing SHIP BLOCKED panel); unattended → preserve completed work,
push, open a `[FAILED]` PR with the failure summary, exit non-zero. If context
cannot be determined, default to the **unattended** behaviour (never hang).

**Rationale**: Preserves the genuine value of the old autonomous path (CI needs an
artifact + non-zero exit) while removing the manual, unenforced flag. Uses
standard environment signals available to every host, per FR-017.

**Alternatives considered**: always-stop (loses CI usefulness) and always-PR
(noisy interactively) — both rejected (Q2 answer C).

---

## D6 — Deferred-findings convention (US5, FR-010/011)

**Decision**: Add `steering/findings.md` defining two finding classes and a
standard entry format: **report-upstream** (fix at source) and
**before-production** (staging-acceptable, resolve before prod). `bw-work` and
`bw-ship` reference it so findings are captured *as they occur* into one known,
discoverable location. Start as a **convention** (KISS/YAGNI): no dedicated
command in v1. The format is defined once in steering; commands prompt capture at
the moments findings arise.

**Rationale**: Satisfies discoverability and consistency without new command
surface. Buildwright-owned (the convention + format); explicitly does NOT seed
files into any consuming service template (out of scope).

**Alternatives considered**:
- *Dedicated `/bw-report-upstream` command* — deferred; revisit only if the
  convention proves insufficient (YAGNI).
- *Per-service seed files via `setup.sh`* — out of scope (service-template
  concern).

---

## D7 — Flag removal mechanics + gate (US6, FR-013/015)

**Decision**: Remove every `BUILDWRIGHT_AUTO_APPROVE` reference from
`.buildwright/commands/*` (bw-plan, bw-work, bw-ship, bw-analyse), `AGENTS.md`,
and reconcile the constitution's Principle I wording to the flagless model. Add
`scripts/validate-no-auto-approve.sh` (modelled on `validate-docs.sh`) that exits
non-zero if the string appears in canonical sources or root docs, and wire it into
`make validate`.

**Rationale**: FR-013/015 require zero references and a single behaviour; an
automated gate makes the requirement testable (Principle II) and prevents
regression. The constitution change goes through its own governance wording but is
part of this work item (FR-015).

**Alternatives considered**: documentation-only removal without a gate — rejected;
nothing would stop the flag creeping back.
