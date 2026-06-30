# Tasks → Issues

How an approved plan's tasks become tracked GitHub issues: a **parent** issue for the
change, plus a **child** issue per independent unit of work. This is a convention; there
is no dedicated command. `/bw-plan` produces an *issue-ready* breakdown; the issues are
**created at the `/bw-work` handoff** (or by a host's CI), never by `/bw-plan` itself
(see its hard constraints).

## The shape

- **Parent issue** — the change as a whole. Title is the change name; body links the
  plan and lists the children as a task list.
- **Child issue per unit of work** — one per independently testable, deliverable unit, so
  each can drive its own `/bw-work` loop. **What counts as a "unit" is project-defined** —
  a task, a vertical slice, or a module; pick the grain that matches how your loop consumes
  work. (Thin end-to-end slices usually beat horizontal layers.)

## Stable IDs (so re-runs are idempotent)

Each child carries a **stable ID** taken from the plan, written once at the front of the
title (`<id>: <desc>`). The ID — not the prose, and not an ordinal number — is the
identity, so regenerating or renumbering the plan and re-running keeps the same issue.

## Idempotent creation

Before creating anything, **list the existing issues and skip any ID that already has
one** — re-running adds only what's new and reports the skips. Match an existing issue to
an ID by its leading `<id>:`.

## Remote guard

Only create issues in the repository matching the current git remote
(`git config --get remote.origin.url`). If the remote is missing or isn't the intended
repository, **stop and report** — never create issues anywhere else.

## Mechanism (`gh`)

Use the `gh` CLI, so this runs the same locally and in CI.

```sh
# guard: confirm the remote is the intended repo before any write
git config --get remote.origin.url   # verify this is the repo you mean to write to

# parent
gh issue create --title "<change name>" --body "Plan: <link>\n\nChildren:\n- [ ] <id> …"

# child (one per unit), skipping IDs that already have an issue
gh issue create --title "<id>: <desc>" --body "Parent: #<parent>\n<acceptance from the plan>"
```

Link children to the parent (`Parent: #<n>` in the body; the children task-list in the
parent). Labels are project-defined (e.g. a label your build loop watches).

## Rules

- `/bw-plan` only **prepares** the breakdown (parent + child-per-unit, stable IDs); it does
  not create issues. Creation happens at the `/bw-work` handoff.
- Always run the **remote guard** first; never create issues in a non-matching repo.
- Always **dedup by ID**; re-running must update, never duplicate.
- This convention is Buildwright's; it prescribes no project-specific unit grain or labels,
  and seeds no files into any project.
