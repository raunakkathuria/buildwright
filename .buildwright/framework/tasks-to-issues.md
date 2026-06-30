# Tasks → Issues

How an approved plan's tasks become tracked GitHub issues: a **parent** issue for the
change, plus a **child** issue per independent workstream. This is a
convention; there is no dedicated command. `/bw-plan` produces an *issue-ready*
decomposition; the issues are **created at the `/bw-work` handoff** (or by the host's
orchestrator) — `/bw-plan` itself never creates them (see its hard constraints).

## The shape

- **Parent issue** — the change as a whole. Title is the change/slice name; body links
  the spec/plan and lists the children as a task list.
- **Child issue per workstream** — one per independent stream of work, each by itself
  testable and deliverable, so it can later drive its own `/bw-work` loop. The workstream
  dimension is **project-defined**; the default for a full-stack product is
  **web · mobile · API · database · journey tests**. Omit streams a change doesn't touch.

## Stable IDs (so re-runs are idempotent)

Each child carries a **stable ID** taken from the plan (the slice/task ID), written once
at the front of the title: `T003: api — add rate-limit headers`. The ID — not the prose —
is the identity. Regenerating the plan and re-running keeps the same IDs, so nothing is
duplicated.

## Idempotent creation (borrowed discipline)

Before creating anything, **list the existing issues and skip any ID that already has
one** — re-running after a regenerated plan adds only what's new, and reports the skips.
Match an existing issue to an ID by the leading `<ID>:` in its title.

## Remote guard (never create in the wrong repo)

Only create issues in the repository matching the current git remote
(`git config --get remote.origin.url`). If the remote is missing or is not the intended
GitHub repository, **stop and report** — never create issues anywhere else.

## Mechanism (`gh`)

Use the `gh` CLI (not an MCP), so this runs the same locally and in CI.

```sh
# guard
case "$(git config --get remote.origin.url)" in
  *github.com[:/]<org>/<repo>*) : ;;   # ok
  *) echo "remote is not the expected repo — stopping"; exit 1 ;;
esac

# parent
gh issue create --title "<change name>" --body "Spec/plan: <link>\n\nChildren:\n- [ ] T001 …"

# child (one per workstream), skipping IDs that already have an issue
gh issue create --title "T001: api — <desc>" \
  --body "Parent: #<parent>\nWorkstream: api\n<acceptance from the plan>" \
  --label api
```

Link children to the parent (`Parent: #<n>` in the body; the children task-list in the
parent). Labels per workstream are optional but help filtering.

## Rules

- `/bw-plan` only **prepares** the decomposition (parent + child-per-workstream, stable
  IDs); it does not create issues. Creation happens at the `/bw-work` handoff.
- Always run the **remote guard** first; never create issues in a non-matching repo.
- Always **dedup by ID**; re-running must update, never duplicate.
- This convention is Buildwright's; it seeds no files into any specific service template.
