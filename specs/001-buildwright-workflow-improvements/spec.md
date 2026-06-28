# Feature Specification: Buildwright Workflow Improvements

**Feature Branch**: `001-buildwright-workflow-improvements`

**Created**: 2026-06-27

**Status**: Draft

**Input**: Developer feedback from teams using Buildwright on `service-derivpay`
(six reports covering `/bw-plan` and `/bw-work` behaviour, command handoff,
auto-continuation, and capturing deferred findings).

## Scope Note

This spec covers only the **Buildwright-specific** improvements drawn from the
feedback. Service-specific findings (database migration scaffolding, OIDC
discovery, CORS/auth/idempotency middleware, CI coverage gating, Makefile and
Podman fixes) belong to the consuming service's own template and steering
documents, not to Buildwright, and are explicitly out of scope here (see
**Out of Scope**). The two harder, partly host-tool-limited questions —
cross-command context management and the speed/diligence trade-off — are
recorded as **Follow-up Research**, not built here.

A cross-cutting theme runs through the in-scope items: **Buildwright should lean
on the native capabilities of its host agent tools (Claude Code, Codex,
OpenCode, Cursor) — plan mode, structured plan output, task/todo tracking,
sub-agents, hooks, and native command invocation — rather than reimplementing
those behaviours in prose instructions.** Several of the bugs below stem from
Buildwright hand-rolling behaviour the host already provides.

## Clarifications

### Session 2026-06-27

- Q: How is US4 auto-continue governed? → A: Auto-continue is the **default**
  autonomous behaviour — advance through ready items, pause on any genuine
  question/decision/approval, stop when blocked. No dependency on
  `BUILDWRIGHT_AUTO_APPROVE`.
- Q: Should the `BUILDWRIGHT_AUTO_APPROVE` cleanup be folded into this feature? →
  A: Yes — fold it in. The flag is unenforced (no script reads it) and overloaded
  across four commands; retire it in favour of the philosophy-default autonomy
  behaviour as part of this work (US6).
- Q: On failure after retries, what is the single `bw-ship` behaviour once the
  flag is gone? → A: **Infer context** — an interactive session pauses and asks
  the human; an unattended/headless run (CI, no TTY) preserves completed work,
  opens a failure-summary PR, and exits non-zero. No manual flag.
- Q: How does the plan→work handoff (US2) interact with auto-continue (US4)? →
  A: **Auto-continue faithfully** — at the plan→work boundary, invoke the real
  `/bw-work` via the host's native command invocation; where a host cannot
  faithfully invoke, fall back to directing the user to run `/bw-work`. Never run
  implementation from memory.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - `/bw-plan` reliably writes its plan (Priority: P1)

A developer runs `/bw-plan`, the agent finishes thinking and announces it will
write the plan to disk, and the plan file is reliably created. Today the agent
sometimes gets stuck at exactly this step: it says "writing the deliverable
now," then stalls through repeated interrupts, and neither retrying, ESC +
continue, nor quitting and resuming recovers it. The stall occurs regardless of
how full the context is (reported at both near-full and 14%).

**Why this priority**: This is a reproducible bug that blocks the primary output
of `/bw-plan`. When it triggers, the command produces nothing usable and the
developer cannot proceed. Reliability of the core deliverable comes first.

**Independent Test**: Run `/bw-plan` repeatedly across varied context sizes and
plan complexities; confirm the plan deliverable is persisted to disk on the
first attempt every time, with no stuck/interrupt loop at the write step.

**Acceptance Scenarios**:

1. **Given** a completed `/bw-plan` analysis, **When** the agent moves to write
   the plan deliverable, **Then** the file is created on the first attempt
   without entering a stuck or repeated-interrupt state.
2. **Given** a near-full context window, **When** `/bw-plan` writes its plan,
   **Then** the write still completes (or fails with a clear, actionable error)
   rather than hanging silently.
3. **Given** a write step that cannot complete, **When** the failure occurs,
   **Then** the agent reports a specific reason and a recovery action instead of
   looping.

---

### User Story 2 - Faithful handoff from plan to work (Priority: P1)

After `/bw-plan` finishes, the developer is directed to start implementation by
running `/bw-work` (or by an explicit, native command invocation), so that the
implementation step executes the **actual** `/bw-work` instructions. Today,
`/bw-plan` often ends with an inline prompt like "Want me to proceed with Slice
A?"; answering "yes" makes the agent implement from its *memory* of what
`/bw-work` does rather than re-running the real command prompt, producing subtly
different behaviour than typing `/bw-work`.

**Why this priority**: The whole value of Buildwright's discipline is that each
phase runs its defined instructions. A handoff that silently substitutes a
recalled approximation undermines the guarantee that `/bw-work` behaves
consistently, and the divergence is invisible to the developer.

**Independent Test**: Complete a `/bw-plan`, accept the suggested next step, and
confirm the implementation phase runs the same defined `/bw-work` behaviour as
typing `/bw-work` directly (same steps, gates, and discipline) — verified by
comparing the two paths.

**Acceptance Scenarios**:

1. **Given** a completed plan, **When** the workflow crosses into
   implementation, **Then** it faithfully invokes the real `/bw-work` via the
   host's native command invocation (auto-continue), or — where the host cannot
   invoke faithfully — directs the developer to run `/bw-work`; it never runs
   implementation from memory.
2. **Given** the developer chooses to continue, **When** implementation begins,
   **Then** the executed behaviour is the defined `/bw-work` behaviour, not a
   recalled paraphrase of it.
3. **Given** `/bw-plan` output, **When** it presents the next step, **Then** the
   wording does not invite a free-text "yes" that would bypass the real command.

---

### User Story 3 - Prefer native host-tool capabilities (Priority: P2)

Buildwright commands use the host agent tool's built-in capabilities wherever an
equivalent exists, instead of reimplementing them in instruction prose. Examples
the feedback points to: using the host's structured plan/plan-mode output and
file writing for the plan deliverable (US1), using native command invocation for
the plan→work handoff (US2), and using native task/todo tracking for
multi-item sequences (US4).

**Why this priority**: This is the root-cause lever behind several reported
bugs. Hand-rolled equivalents of host features are where the fragility lives
(the stuck writer, the memory-based handoff). Standardising on native
capabilities reduces bugs and token cost and keeps Buildwright aligned with each
tool as it evolves.

**Independent Test**: Audit each `bw-*` command against the host tool's
documented native capabilities; confirm that, where a native capability exists
and fits, the command uses it rather than describing the behaviour in prose.

**Acceptance Scenarios**:

1. **Given** a Buildwright command that produces a plan, **When** it runs on a
   host that offers structured plan output / plan mode, **Then** it uses that
   native capability rather than a bespoke text-then-write sequence.
2. **Given** a command that tracks multiple steps, **When** it runs on a host
   with native task/todo tracking, **Then** it uses that tracking rather than an
   ad-hoc in-prose checklist.
3. **Given** a host tool that lacks a given native capability, **When** the
   command runs there, **Then** it falls back gracefully to a documented
   prose-based behaviour without breaking.

---

### User Story 4 - Auto-continue through a ready queue (Priority: P2)

When a developer has a sequence of ready, planned items (e.g. the next unchecked
items in an implementation plan) and there are no open questions, Buildwright
proceeds through them by default without the developer manually re-invoking the
command for each one. When a genuine question, decision, or approval point
arises, it pauses and asks; when it is genuinely blocked, it stops. This is the
natural expression of the autonomy principle, not a special mode behind a flag.

**Why this priority**: A quality-of-life improvement that reduces repetitive
manual re-invocation. It is valuable but secondary to correctness (US1–US3), and
must preserve human-in-the-loop control through genuine pause points rather than
a global toggle.

**Independent Test**: With a plan containing several question-free ready items,
start the workflow once and confirm it advances through the items without a
manual re-invoke per item, while still pausing the moment a decision or question
is required.

**Acceptance Scenarios**:

1. **Given** multiple ready items with no open questions, **When** the workflow
   runs, **Then** it advances through them without requiring a manual command
   re-invocation for each item.
2. **Given** an item that raises a question or decision, **When** the workflow
   reaches it, **Then** it stops and surfaces the question before proceeding.
3. **Given** auto-continue is active, **When** the developer wants to intervene,
   **Then** there is a clear way to pause or stop the sequence.

---

### User Story 5 - Capture deferred findings consistently (Priority: P3)

While working, the agent and developer record two recurring classes of finding
in a consistent, discoverable format: (a) issues that should be fixed at their
source so others benefit ("report upstream"), and (b) decisions that are
acceptable for staging/demo but must be resolved before a production release
("before production"). Today these scatter across PR descriptions, chat threads,
and `// TODO` comments, and get rediscovered from scratch on the next service.

**Why this priority**: Useful hygiene that improves release-readiness and
knowledge capture, but it does not block the core plan→work loop and is lower
priority than the correctness and workflow fixes above. Only the
Buildwright-owned mechanism (a command/convention for recording findings in a
standard format, surfaced by the workflow) is in scope — not seeding files into
any particular service template.

**Independent Test**: During a `/bw-work` run that defers a decision or
discovers an upstream-worthy issue, confirm the finding can be captured in the
standard format through the workflow, and that it is later discoverable in one
known place rather than scattered.

**Acceptance Scenarios**:

1. **Given** an agent defers a decision as "acceptable for staging, fix before
   production," **When** the deferral is made, **Then** it is recorded in the
   standard "before production" format in a known location.
2. **Given** the agent finds an issue better fixed at its source, **When** the
   finding is made, **Then** it is recorded in the standard "report upstream"
   format in a known location.
3. **Given** a developer wants to review deferred work, **When** they look,
   **Then** both classes of finding are discoverable in one consistent place.

---

### User Story 6 - Retire the overloaded autonomy flag (Priority: P2)

`BUILDWRIGHT_AUTO_APPROVE` is removed as a control mechanism. Today it is an
unenforced environment variable (no script reads it) that is overloaded across
four commands with different meanings: approval-before-implementation
(`bw-work`), failure handling (`bw-ship`), defaults-vs-ask (`bw-plan`), and
doc-overwrite-vs-ask (`bw-analyse`). In its place, every command follows the
single autonomy default from the constitution: execute autonomously, pause only
when a decision is genuinely the human's to make, and stop when genuinely
blocked.

**Why this priority**: This is the foundation US4 depends on — auto-continue can
only be "the default" once the flag that contradicted it is gone. It also removes
KISS/YAGNI debt (an unenforced, overloaded knob) and resolves the divergence
between the four commands' behaviours.

**Independent Test**: Search the canonical configuration and agent docs for
`BUILDWRIGHT_AUTO_APPROVE`; confirm zero references remain and that each of the
four affected commands documents a single, consistent autonomy behaviour.

**Acceptance Scenarios**:

1. **Given** the canonical `.buildwright/` config and `AGENTS.md`, **When**
   searched for `BUILDWRIGHT_AUTO_APPROVE`, **Then** there are zero references.
2. **Given** any of the four previously flag-gated commands, **When** it reaches
   a point that used to branch on the flag, **Then** it follows the single
   autonomy default (proceed; pause only on a genuine decision; stop when
   blocked) with no environment-variable dependency.
3. **Given** the project constitution references the flag in its autonomy
   principle, **When** this feature ships, **Then** that governance reference is
   reconciled to the flagless autonomy model.

---

### Edge Cases

- **Plan write fails for a real reason** (permissions, disk, invalid path): the
  command must report the specific cause and a recovery step, never hang (US1).
- **Host tool lacks a native capability** Buildwright wants to use: the command
  must degrade to a documented prose fallback rather than fail (US3).
- **Auto-continue meets an ambiguous item** that is *almost* a question: the
  workflow must err toward pausing rather than guessing when confidence is low
  (US4), consistent with the constitution's autonomy-with-verification stance.
- **Auto-continue reaches an approval point** (a decision genuinely the human's
  to make): the workflow must pause and ask rather than proceed, even though no
  flag governs the behaviour (US4/US6).
- **Findings captured with no target file present**: the capture mechanism must
  still record the finding somewhere discoverable rather than discard it (US5).
- **Execution context cannot be determined** on `bw-ship` failure: the workflow
  must default to the safe unattended behaviour (preserve work, failure-summary
  PR, non-zero exit) rather than hang waiting for input that may never come
  (US6/FR-016).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `/bw-plan` MUST persist its plan deliverable to disk reliably,
  without entering a stuck or repeated-interrupt state at the write step,
  independent of context-window fullness.
- **FR-002**: When the plan deliverable cannot be written, `/bw-plan` MUST
  surface a specific, actionable error and recovery path instead of stalling
  silently.
- **FR-003**: At the plan→work boundary, the workflow MUST faithfully invoke the
  real `/bw-work` through the host's native command-invocation mechanism
  (auto-continue per US4); where the host cannot invoke a command faithfully, it
  MUST instead direct the developer to run `/bw-work`. It MUST NOT run
  implementation from the agent's memory of `/bw-work`, and MUST NOT offer an
  inline free-text "proceed?" path that bypasses the real command.
- **FR-004**: When implementation continues after planning, the executed
  behaviour MUST be the defined `/bw-work` behaviour (same steps, gates, and
  discipline as typing `/bw-work`), not a recalled approximation.
- **FR-005**: Buildwright commands MUST prefer the host agent tool's native
  capabilities — structured plan output / plan mode, file writing, task/todo
  tracking, sub-agents, hooks, and native command invocation — over
  reimplementing equivalent behaviour in instruction prose, wherever such a
  capability exists and fits the need.
- **FR-006**: Where a host tool lacks a native capability Buildwright relies on,
  the affected command MUST degrade gracefully to a documented fallback rather
  than fail.
- **FR-007**: Buildwright MUST support advancing through a sequence of ready,
  question-free items without requiring a manual command re-invocation per item.
- **FR-008**: Auto-continuation MUST pause and surface a question whenever a
  genuine decision, ambiguity, approval point, or low-confidence situation
  arises, and MUST stop when genuinely blocked — with no dependency on an
  environment-variable mode flag.
- **FR-013**: `BUILDWRIGHT_AUTO_APPROVE` MUST be removed from all canonical
  configuration (`.buildwright/`) and agent docs (`AGENTS.md`); each of the four
  previously flag-gated commands (`bw-work`, `bw-ship`, `bw-plan`, `bw-analyse`)
  MUST document a single autonomy behaviour with no flag branch.
- **FR-014**: The single autonomy behaviour MUST be: execute autonomously, pause
  only when a decision is genuinely the human's to make, and stop when genuinely
  blocked — consistent across all commands.
- **FR-016**: On failure after retries, `bw-ship` MUST infer execution context
  rather than read a manual flag: in an interactive session it MUST pause and ask
  the human; in an unattended/headless run (e.g. CI, no TTY) it MUST preserve
  completed work, open a PR with a failure summary, and exit non-zero.
- **FR-017**: Context inference (interactive vs unattended) MUST rely on
  environment signals available to the host (e.g. TTY presence, CI environment
  variables), not on Buildwright-specific configuration.
- **FR-015**: Governance references to `BUILDWRIGHT_AUTO_APPROVE` (notably the
  constitution's autonomy principle) MUST be reconciled to the flagless model.
- **FR-009**: The developer MUST be able to pause or stop an in-progress
  auto-continued sequence.
- **FR-010**: Buildwright MUST provide a consistent, discoverable mechanism to
  record two classes of finding — "report upstream" (fix at source) and "before
  production" (staging-acceptable, resolve before prod) — in a standard format.
- **FR-011**: The findings mechanism MUST surface these finding types within the
  normal workflow so they are captured as they occur rather than rediscovered
  later, and MUST keep them discoverable in one known place.
- **FR-012**: All in-scope changes MUST be made in `.buildwright/` (the
  canonical, committed configuration) and propagated via `make sync`; generated
  tool-specific directories MUST NOT be hand-edited (per project convention).

### Key Entities

*Not applicable — this feature changes command behaviour and conventions, not a
persistent data model.*

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `/bw-plan` persists its deliverable on the first attempt in at
  least 99% of runs across varied context sizes, with zero stuck/interrupt loops
  observed in a repeated-run test set (currently fails intermittently).
- **SC-002**: 100% of plan→work handoffs execute the defined `/bw-work`
  behaviour rather than a recalled approximation, verified by comparing the
  "accept next step" path against typing `/bw-work` directly.
- **SC-003**: For a queue of N ready, question-free items, the developer
  performs zero per-item manual command re-invocations, while every genuine
  question still triggers a pause.
- **SC-004**: An audit of all `bw-*` commands finds zero cases where a command
  reimplements in prose a native host capability that exists and fits, among the
  capabilities identified in this spec (plan output, file writing, task
  tracking, command invocation).
- **SC-005**: Deferred decisions and upstream-worthy findings are captured
  through the workflow in a single consistent format and location in 100% of
  observed cases, instead of scattering across PRs, chats, and TODO comments.
- **SC-006**: Across a representative set of host tools, every in-scope command
  either uses the native capability or falls back without error (no command
  breaks on a host that lacks a given capability).

## Assumptions

- **Autonomy default** (clarified 2026-06-27): Auto-continuation (US4) is the
  default autonomous behaviour, not a flagged mode. The workflow advances through
  ready, question-free items and pauses only on a genuine decision/approval or
  when blocked. The `BUILDWRIGHT_AUTO_APPROVE` flag is being retired in this same
  feature (US6) because it is unenforced and overloaded; the single autonomy
  behaviour replaces it everywhere.
- **Findings mechanism shape**: US5 is satisfied by a lightweight, standard
  convention surfaced through existing commands (optionally a dedicated capture
  command); choosing command-vs-convention is a planning decision, not a spec
  decision. Seeding files into any specific service template is out of scope.
- **Primary host tool**: Claude Code is the primary host for validation; Codex,
  OpenCode, and Cursor are supported via graceful fallback (FR-006). The set of
  "native capabilities" is taken from each tool's documented features at
  implementation time — see
  [research-native-capabilities.md](./research-native-capabilities.md).
- **All four hosts already provide the needed primitives** (verified mid-2026):
  a native plan-vs-build mode separation (Claude Code plan mode +
  `EnterPlanMode`/`ExitPlanMode`; Codex `/plan`; Cursor Plan mode; OpenCode
  built-in Plan/Build agents), native command/skill invocation (e.g. Claude
  Code's `Skill` tool re-injects the real prompt), native task tracking, native
  subagents, and lifecycle hooks. `/bw-plan` and `/bw-work` should map onto these
  native modes rather than reimplement them — which is the suspected root cause
  of both the US1 stuck-writer and the US2 memory-based handoff.
- **Root cause of the stuck writer** (US1) is assumed to be a bespoke
  text-then-write pattern that a native plan/file-writing capability would
  avoid; planning will confirm the actual cause before fixing.

## Out of Scope

These come from the feedback but are **not** Buildwright concerns — they belong
to the consuming service's template/steering and are excluded:

- Database migration scaffolding (`goose`, `migrate` package, `migrations/`).
- OIDC discovery vs separate token/JWKS URLs.
- CORS / auth / idempotency middleware in the service template.
- CI coverage gate behaviour with skipped integration tests / `DATABASE_URL`.
- `setup.sh` `${MODULE_NAME}` substitution, Docker-vs-Podman Makefile support.
- `install-hooks` target collision in the service's split Makefile (a
  service-template build concern, addressed in that repo).

## Follow-up Research *(not built in this feature)*

Captured for a separate research track; partly constrained by host-tool
limitations and needing investigation before they are specifiable:

- **Cross-command context management** (feedback 4): carrying forward only the
  relevant slices of conversation between `/bw-plan` and `/bw-work` (e.g. stash
  context, work in a fresh generated context, restore) instead of accumulating
  the full transcript or forcing `/clear`. Currently limited by what the host
  agent exposes to commands/plugins.
- **Speed / diligence trade-off** (feedback 5): why the full `/bw-plan` →
  `/bw-work` pipeline is materially slower and more interactive than a direct
  ask, and whether a library of pre-baked, pullable modules/providers for common
  internal services (and reference-vs-copy semantics) would close the gap.
