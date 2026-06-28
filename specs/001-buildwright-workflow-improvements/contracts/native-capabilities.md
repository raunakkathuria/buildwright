# Contract: Native-capability preference & fallback

Backs `steering/native-capabilities.md`. Covers US3 (FR-005/006).

## Rule

For each capability Buildwright relies on, a command **MUST** use the host's
native equivalent where it exists and fits, and **MUST** fall back to a documented
prose behaviour where the host lacks it — never failing (FR-006).

## Capabilities & fallbacks (data-model §2)

| Capability | Native use | Fallback when absent |
|------------|-----------|----------------------|
| `plan-file-write` | host file-write tool, single decisive write | prose: write file directly, report errors |
| `command-invocation` | faithful re-injection of the real command | direct the user to run the command |
| `task-tracking` | host task/todo tracking for multi-item queues | in-prose checklist in the deliverable |
| `subagents` | host sub-agent for isolated phases | run inline in the main flow |
| `hooks` | host lifecycle hooks where helpful | no hook; explicit step in the command |

## Authoring constraint

- Canonical command text **MUST** reference capabilities **generically**; the
  per-host mechanism lives only in `steering/native-capabilities.md` (keeps
  `.buildwright/` tool-agnostic).

**Acceptance** (maps to US3/SC-004): an audit of `bw-*` commands finds zero cases
where a command reimplements in prose a native capability that exists and fits.
