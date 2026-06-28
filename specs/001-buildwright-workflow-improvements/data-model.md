# Data Model: Buildwright Workflow Improvements

There is **no persistent/database data model** — Buildwright is a markdown +
shell framework. What follows are the conceptual schemas the design relies on:
the finding record, the native-capability map, the autonomy decision state, and
the execution-context signal. These define structure for the steering docs and
contracts, not runtime storage.

---

## 1. Finding Record (US5, FR-010/011)

A captured deferred finding. Lives in a known per-project location (e.g. a
project's `TODO_BEFORE_PRODUCTION.md` / upstream-issues doc — location is the
consuming project's, the *format* is Buildwright's).

| Field | Type | Notes |
|-------|------|-------|
| `class` | enum | `report-upstream` \| `before-production` |
| `title` | string | short descriptive name |
| `context` | string | where/why it arose (file:line, command, decision) |
| `detail` | string | symptom / decision and its scope |
| `staging_ok_reason` | string | (before-production only) why staging/demo is fine |
| `before_prod_action` | string | (before-production only) what must happen first |
| `upstream_fix` | string | (report-upstream only) hypothesised source fix |
| `status` | enum | `open` \| `resolved` (resolved items move to history) |

**Rules**: required fields differ by `class` (the two `before_prod_*` for
before-production; `upstream_fix` for report-upstream). Captured at the moment the
finding arises, not retroactively. One known location per class per project.

---

## 2. Native Capability Map Entry (US3, FR-005/006)

One row per capability Buildwright relies on, mapping to each host. Backs
`steering/native-capabilities.md`.

| Field | Type | Notes |
|-------|------|-------|
| `capability` | enum | `plan-file-write` \| `command-invocation` \| `task-tracking` \| `subagents` \| `hooks` |
| `claude_code` | string | native mechanism name or `none` |
| `codex` | string | native mechanism name or `none` |
| `cursor` | string | native mechanism name or `none` |
| `opencode` | string | native mechanism name or `none` |
| `fallback` | string | documented prose behaviour when host = `none` |

**Rules**: every capability MUST define a `fallback` (FR-006 — never fail on a
host lacking the capability). Commands reference `capability` generically; the map
resolves the host-specific mechanism.

---

## 3. Autonomy Decision State (US4/US6, FR-007/008/014)

The state a command is in while advancing through work. Backs
`steering/autonomy.md`. Not stored — it is the decision the agent makes per step.

| State | Trigger | Action |
|-------|---------|--------|
| `proceed` | next item ready, no open question | execute it, then re-evaluate |
| `pause` | genuine decision/approval/ambiguity or low confidence | surface the question, wait for human |
| `stop` | genuinely blocked (missing input, failed gate after retries) | report blocker; on `bw-ship` apply context-inferred failure handling |

**Rules**: no environment-variable flag participates in this decision (FR-008/014).
`pause` is the human-in-the-loop point. The developer may interrupt during
`proceed` to force a `pause`/`stop` (FR-009).

---

## 4. Execution Context Signal (FR-016/017)

Inferred at `bw-ship` failure time; not configured.

| Field | Type | Notes |
|-------|------|-------|
| `interactive` | bool | true if a TTY is attached (`[ -t 0 ]` / `[ -t 1 ]`) and no CI signal |
| `ci` | bool | true if `CI`, `GITHUB_ACTIONS`, or equivalent is set |
| `resolved_mode` | enum | `interactive` → ask; `unattended` → preserve+PR+exit≠0 |

**Rules**: `ci` true OR `interactive` false ⇒ `unattended`. Indeterminate ⇒
default `unattended` (never hang — edge case in spec). No Buildwright-specific
config participates (FR-017).
