---
name: bw-claw
description: Multi-agent feature development using the Claw Architecture — Architect decomposes work, specialized claws execute per domain
arguments:
  - name: feature
    description: Feature description or path to requirements file
    required: true
  - name: claws
    description: Comma-separated list of claws to use (e.g., "frontend,backend,database"). Auto-detected if omitted.
    required: false
---

## Claw Architecture Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                   CLAW ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. ANALYZE      → Architect reads codebase structure        │
│  2. DECOMPOSE    → Break into domain-specific claw tasks     │
│  3. CONTRACT     → Define interfaces + naming conventions    │
│  4. APPROVE      → Human reviews decomposition plan          │
│  5. EXECUTE      → Each claw grabs its domain work           │
│  6. INTEGRATE    → Architect combines + verifies             │
│  7. SHIP         → Buildwright quality gates → PR            │
│                                                              │
│         🧠 Architect (Brain)                                 │
│              │                                               │
│    ┌─────────┼─────────┐                                     │
│    │         │         │                                     │
│  🎨 UI    ⚙️ API    🗄️ DB                                   │
│  Claw     Claw     Claw                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Adopt Architect Persona

Read and adopt the Architect persona from `.buildwright/agents/architect.md`.

---

## Phase 2: Analyze Project Structure

Determine what domains exist in this project:

```bash
# Detect project layers
ls -d */ 2>/dev/null
find . -maxdepth 2 -name "package.json" -o -name "Cargo.toml" -o -name "go.mod" -o -name "pyproject.toml" 2>/dev/null
```

Map directories to domains:

| Pattern | Domain | Claw |
|---------|--------|------|
| `ui/`, `frontend/`, `src/components/`, `app/` | Frontend | `.buildwright/claws/frontend.md` |
| `api/`, `backend/`, `server/`, `src/routes/` | Backend | `.buildwright/claws/backend.md` |
| `database/`, `db/`, `migrations/`, `prisma/` | Database | `.buildwright/claws/database.md` |
| `gateway/`, `nginx/`, `proxy/` | Gateway | Custom claw needed |
| `core/`, `domain/`, `services/` | Business Logic | Custom claw needed |

If `$ARGUMENTS.claws` is provided, use those specific claws.
Otherwise, auto-detect from project structure.

---

## Phase 3: Read Requirements

If `$ARGUMENTS.feature` is a file path, read it.
Otherwise, treat as inline description.

Read steering documents:
```bash
cat .buildwright/steering/product.md
cat .buildwright/steering/tech.md
cat .buildwright/steering/naming-conventions.md
```

---

## Phase 4: Decompose into Claw Tasks

Following the Architect persona's decomposition process:

### 4.1 Identify Which Domains Are Affected

Not every feature touches every domain. Determine the minimal set of claws needed.

### 4.2 Define Interface Contract

Before any claw starts, define the contract:

```markdown
## Interface Contract: [Feature Name]

### New Fields
| Concept | Database | API (JSON) | UI (JS) |
|---------|----------|------------|---------|
| [field] | [snake_case] | [camelCase] | [camelCase] |

### New Endpoints
| Method | Path | Request | Response |
|--------|------|---------|----------|
| [verb] | [path] | [schema] | [schema] |
```

### 4.3 Update Naming Conventions

Add new fields to `.buildwright/steering/naming-conventions.md`:
- Register all new fields in the Canonical Field Registry
- Register all new endpoints in the Canonical Endpoint Registry

### 4.4 Determine Execution Order

```
PARALLEL:   Claws with no dependencies → run simultaneously
SEQUENTIAL: Claw B depends on Claw A → run A first
MIXED:      Some parallel, some sequential
```

### 4.5 Create Claw Task Descriptions

For each claw, write a specific task:

```markdown
## Claw Task: [Domain] — [Feature]

### Context
[What this claw needs to know]

### Interface Contract (relevant subset)
[Fields, endpoints, types this claw uses]

### Specific Work
1. [Step 1]
2. [Step 2]

### Acceptance Criteria
- [Criterion 1]
- [Criterion 2]
```

---

## Phase 5: Present Decomposition Plan

```
═══════════════════════════════════════════════════════════════
CLAW ARCHITECTURE PLAN
═══════════════════════════════════════════════════════════════

Feature: [name]
Claws: [list]
Execution: [PARALLEL / SEQUENTIAL / MIXED]

INTERFACE CONTRACT
──────────────────
[fields table]
[endpoints table]

CLAW TASKS
──────────
🗄️ DB Claw:  [summary]  [parallel/depends on: X]
⚙️ API Claw: [summary]  [parallel/depends on: DB]
🎨 UI Claw:  [summary]  [parallel/depends on: API]

EXECUTION ORDER
───────────────
[diagram]

═══════════════════════════════════════════════════════════════

Reply "approved" to proceed.
Reply with feedback to revise.
═══════════════════════════════════════════════════════════════
```

**If BUILDWRIGHT_AUTO_APPROVE is not set to `false`:**
- Commit the plan to `docs/specs/[feature]/claw-plan.md`
- Proceed directly to execution

**If BUILDWRIGHT_AUTO_APPROVE=false:**
- STOP and wait for "approved"

---

## Phase 6: Execute Claw Tasks

### Single-Agent Mode (Default — Claude Code / OpenCode)

Execute claws sequentially within a single agent session. For each claw:

1. **Load claw persona** — Read `.buildwright/claws/[domain].md`
2. **Scope context** — Read ONLY the claw's domain directories
3. **Execute** — Follow the claw's process (TDD, implement, verify)
4. **Record output** — Write claw report to `docs/specs/[feature]/claw-[domain].md`
5. **Return to Architect** — Load architect persona for next claw or integration

```
ARCHITECT: Decompose → Plan
  └─ Switch to DB Claw persona
     └─ Execute DB work → Report
  └─ Switch to API Claw persona
     └─ Execute API work → Report
  └─ Switch to UI Claw persona
     └─ Execute UI work → Report
ARCHITECT: Integrate → Ship
```

### Multi-Agent Mode (OpenClaw / Parallel Terminals)

For true parallel execution, the Architect outputs instructions for spawning separate agents:

```bash
# Claude Code — separate terminal sessions
# Terminal 1: DB Claw
claude "Read .buildwright/claws/database.md and execute: [DB task]"

# Terminal 2: API Claw (after DB completes if sequential)
claude "Read .buildwright/claws/backend.md and execute: [API task]"

# Terminal 3: UI Claw
claude "Read .buildwright/claws/frontend.md and execute: [UI task]"
```

```bash
# OpenCode — separate agent sessions
opencode agent run database "[DB task]"
opencode agent run backend "[API task]"
opencode agent run frontend "[UI task]"
```

```
# OpenClaw — agent-to-agent messaging
Send to @database: "[DB task]"
Send to @backend: "[API task]"
Send to @frontend: "[UI task]"
```

Write task assignments to `docs/specs/[feature]/claw-tasks.md` for coordination.

---

## Phase 7: Integration (Architect Resumes)

After all claws complete, the Architect:

### 7.1 Read All Claw Reports
```bash
cat docs/specs/[feature]/claw-*.md
```

### 7.2 Verify Interface Compliance
- Do the DB columns match the API expectations?
- Do the API responses match the UI expectations?
- Are naming conventions consistent?

### 7.3 Run Integration Verification
```bash
# Full project verification
/bw-verify
```

### 7.4 Fix Integration Issues
If interfaces don't align:
1. Identify which claw's output is wrong
2. Fix the integration gap (minimal changes)
3. Re-verify

---

## Phase 8: Ship

Run `/bw-ship` which chains: verify → security → review → release.

---

## Final Report

```
═══════════════════════════════════════════════════════════════
CLAW ARCHITECTURE COMPLETE
═══════════════════════════════════════════════════════════════

Feature: [name]
Branch: feature/[name]
PR: [URL]

CLAWS EXECUTED
──────────────
🗄️ DB Claw:  ✅ [summary of changes]
⚙️ API Claw: ✅ [summary of changes]
🎨 UI Claw:  ✅ [summary of changes]

INTEGRATION
───────────
Interface compliance: ✅
Naming conventions: ✅
Integration tests: ✅

QUALITY GATES
─────────────
✅ Verify (typecheck, lint, test, build)
✅ Security (OWASP, secrets, dependencies)
✅ Review (Staff Engineer)
✅ Shipped

ARTIFACTS
─────────
• Plan: docs/specs/[feature]/claw-plan.md
• DB Report: docs/specs/[feature]/claw-database.md
• API Report: docs/specs/[feature]/claw-backend.md
• UI Report: docs/specs/[feature]/claw-frontend.md

═══════════════════════════════════════════════════════════════
```

---

## When NOT to Use /bw-claw

Use standard `/bw-new-feature` or `/bw-quick` when:
- Feature touches only one domain
- Project has no clear domain separation (monolith)
- Task is small (< 2 hours)
- Changes don't cross layer boundaries

The overhead of multi-agent coordination isn't worth it for simple tasks. Start with `/bw-quick` or `/bw-new-feature` and escalate to `/bw-claw` when you see cross-domain complexity.
