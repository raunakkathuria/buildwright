---
name: bw-plan
description: Research a question or topic and produce a written deliverable — no implementation, no commits
arguments:
  - name: question
    description: A question, topic, or path to a structured task file (.md)
    required: true
---

# /bw-plan — Research and Planning Without Implementation

## When to use

Research and planning tasks where the output is a written deliverable — not
implementation. Use when someone asks a question, wants an analysis, or needs
a structured plan/report before (or instead of) writing code.

Examples:
- "What are the performance risks in this Flutter app?"
- "Plan a migration from monolith to microservices"
- "Evaluate which payment provider we should use"
- "Produce a static analysis report for this codebase"

**Contrast with other commands:**
- `/bw-new-feature` — research + spec + implement + ship
- `/bw-quick` — implement immediately (no planning doc)
- `/bw-analyse` — analyse this project's own codebase for Buildwright context
- `/bw-plan` — research a question, write a deliverable, stop there

## Invocation

```
/bw-plan [question or topic | path/to/task.md]
```

**Inline question:**
```
/bw-plan "what are the performance risks in this Flutter app?"
/bw-plan "plan a migration from REST to GraphQL"
/bw-plan "compare Redis vs Memcached for our session cache"
```

**Structured task file:**
```
/bw-plan tasks/flutter-perf-review.md
/bw-plan .buildwright/tasks/architecture-review.md
```

---

## Phase 1 — Understand

If a **task file** is provided, read it. Extract:
- `Inputs` block — variable names, descriptions, defaults
- `Rules` block — constraints on evidence, scope, output format
- `Research Areas` block — what categories to investigate
- `Outputs` block — file names and content requirements

Substitute any `<placeholder>` tokens from invocation args or sensible defaults
(e.g. `<date>` → today's date, `<repo_path>` → current working directory).

If **inline text** is provided, infer:
- The question or goal
- Likely research areas from the question
- Default output location: `docs/plans/<kebab-slug>/<YYYY-MM-DD>/plan.md`

---

## Phase 2 — Clarify

In **interactive mode** (`BUILDWRIGHT_AUTO_APPROVE=false`): if a critical input
is ambiguous (e.g. target repository path is unknown), ask one focused question
before proceeding.

In **autonomous mode** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): apply
sensible defaults and proceed. Note any assumptions in the deliverable.

---

## Phase 3 — Research

Read relevant code, config, and documentation. Run read-only tools listed in
the task (e.g. `flutter analyze`, `dart analyze`, `npm audit`, `cargo audit`,
`semgrep --config auto`). Capture all stdout/stderr as labeled evidence.

**Evidence labels (use exactly these):**
- `inferred from code` — finding comes from reading source files
- `backed by tool output` — finding is confirmed by a tool's output
- `backed by docs/external source` — finding references documentation

**Do NOT:**
- Modify any source file
- Run commands that write to the target repository
- Run build steps unless the task explicitly requires them

If a tool is unavailable, note it as a blocker in the summary; skip and continue.

---

## Phase 4 — Synthesize

Organize findings into structured sections per the task's Research Areas (or
inferred categories for inline questions).

**For analysis/audit tasks**, each finding includes:
- `title` — short descriptive name
- `category` — from the task's research areas
- `severity` — critical / high / medium / low
- `confidence` — high / medium / low
- `evidence_type` — one of the three labels above
- `evidence` — file path + line number, or tool command + output excerpt
- `why it matters` — impact on users or system
- `recommended action` — concrete fix or next step
- `estimated effort` — hours/days rough estimate
- `needs_runtime_verification` — true/false

**For planning/decision tasks**, structure around:
- Options considered
- Recommendation
- Rationale
- Risks and mitigations
- Next steps

---

## Phase 5 — Write Deliverable

Write artifact files to `output_dir`. Must write at minimum:
- `plan.md` — or the task-specified primary document

May also write supporting files if the task specifies them:
- `.csv` — comma-separated with a header row
- `.json` — valid JSON, schema as specified in task
- Additional `.md` files (e.g. `top10.md`, `backlog.md`)

Create `output_dir` if it does not exist.

---

## Phase 6 — Summarize

Print to stdout:
- Output directory path and files written
- Top 3–5 findings or key recommendations
- Any blockers that prevented complete research (tools unavailable, files inaccessible)

---

## Hard Constraints (always enforced)

- **NEVER** modify source files in any target repository
- **NEVER** commit, push, or create PRs
- **NEVER** claim something is "measured" or "confirmed" without direct evidence
- Every finding must cite evidence (file + line, or tool output excerpt)
- The task's `Rules` block can add constraints; it cannot remove these hard constraints

---

## Task File Format

Structured task files follow this template:

```markdown
## Inputs
- `<variable_name>`: description [default: value]
- `<repo_path>`: path to the repository to analyse [default: current directory]
- `<output_dir>`: where to write artifacts [default: docs/plans/<slug>/<date>/]

## Rules
1. This is a read-only pass. Do not modify any source files.
2. Separate findings by evidence type: inferred / tool-backed / doc-backed.
3. Every finding must include a file path and line reference or tool output.

## Research Areas
1. Category A — what to look for
2. Category B — what to look for
3. ...

## Outputs
- `plan.md` — primary report with executive summary and all findings
- `top10.md` — top 10 prioritized findings
- `backlog.csv` — all findings as CSV with columns: title,category,severity,confidence,effort
- `summary.json` — machine-readable summary: { findings_count, top_findings[], blockers[] }
```

---

## Example

The Flutter performance review task maps directly to this format:

```
/bw-plan tasks/flutter-perf-review.md
```

Where `tasks/flutter-perf-review.md` defines:
- Inputs: repo_path, main package, entrypoints, target platforms, output_dir
- Rules: static analysis only, evidence required, no source modification
- Research Areas: rebuild risks, list/grid risks, rendering, CPU, data/arch, images, deps, code health
- Outputs: performance-static-review.md, performance-static-top10.md, performance-static-backlog.csv, performance-static-summary.json
