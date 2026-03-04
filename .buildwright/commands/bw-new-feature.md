---
name: bw-new-feature
description: Research codebase, generate spec, validate, get approval, implement with TDD, and ship
arguments:
  - name: requirements
    description: Path to requirements file OR inline description of what to build
    required: true
  - name: skip-research
    description: Skip research phase (not recommended)
    required: false
  - name: parallel
    description: Enable parallel multi-agent implementation
    required: false
---

## Feature Development Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                   NEW FEATURE PIPELINE                      │
├─────────────────────────────────────────────────────────────┤
│  0.   DETECT             → Greenfield or existing project?         │
│  1.   RESEARCH           → Deep-read codebase, understand context  │
│  1.5. RESOLVE AMBIGUITIES → Auto-decide or ask user               │
│  2.   PLAN               → Generate spec informed by research      │
│  3. VALIDATE  → Staff Engineer reviews spec (auto)          │
│  4. APPROVE   → Human reviews and says "approved"           │
│  5. BUILD     → TDD: test → implement → verify              │
│  6. SHIP      → verify → security → review → release        │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 0: Detect (Greenfield or Existing?)

**Check for existing tech indicators:**
- Language manifests: `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `setup.py`
- Dependency files: `requirements.txt`, lock files
- Build files: `Makefile`, `build.gradle`, `CMakeLists.txt`
- Source directories: `src/`, `lib/`, `app/`, `cmd/`
- Git history: `git log --oneline -5` (any commits = existing project)

**Decision:**
- **Any found** → **Existing Project Path**: Run Tech Discovery Protocol (Command Discovery in CLAUDE.md), read steering docs, proceed to Phase 1.
- **None found** → **Greenfield Path** (below).

### Greenfield Path

1. Ask ONE question:
   ```
   This looks like a new project. What is the product vision, and do you have any
   tech constraints (team expertise, deployment environment, integrations, compliance)?
   ```
2. **STOP and wait for the answer.** Do NOT proceed until answered.
3. Derive the stack from the answer — reason from: product type, team knowledge, deployment constraints, scale, compliance. **No hardcoded default stack.**
4. Generate `.buildwright/steering/product.md` and `.buildwright/steering/tech.md` from the answer.
5. At Phase 4 (Human Approval), present the proposed tech stack alongside the spec:
   ```
   PROPOSED TECH STACK
   ───────────────────
   [Stack derived from your requirements]

   Chosen because: [2-3 sentences linking requirements to stack choice]
   Alternatives considered: [brief list]

   Reply "approved" or adjust: "approved, but use X instead of Y"
   ```
6. After approval, finalize `tech.md` with actual commands so future runs use Step 1 of the discovery protocol.

**Existing Project Priority Rule (always apply):**
1. Team's filled-in `tech.md` > auto-detection
2. Existing code patterns > Buildwright conventions
3. Existing deployment config (`Dockerfile`, `k8s/`, `compose.yml`) > DevOps claw defaults
4. Existing test patterns > TDD suggestions in claws
5. Never modify working infrastructure to match Buildwright defaults

---

## Phase 1: Understand Requirements

If $ARGUMENTS.requirements is a file path, read it.
Otherwise, treat it as an inline description.

**Gather:**
- What is being requested
- User personas and goals
- Constraints mentioned
- Success criteria

---

## Phase 2: Research (CRITICAL)

**Skip only if $ARGUMENTS.skip-research is set. Not recommended.**

This phase prevents the #1 failure mode: code that works in isolation but breaks the surrounding system.

### 2.1 Read Steering Documents

```bash
# Always read these first
cat .buildwright/steering/product.md   # Product context
cat .buildwright/steering/tech.md      # Tech stack, commands, patterns
```

Extract:
- Product vision and current focus
- Tech stack and conventions
- Existing patterns to follow
- Commands to use

### 2.2 Deep-Read Relevant Codebase

Based on the requirements, identify and deeply read relevant areas:

```bash
# Find related files
find . -type f -name "*.ts" | xargs grep -l "[relevant terms]"

# Read each file thoroughly - understand, don't skim
```

**Read with these questions:**
- How does similar functionality work today?
- What patterns are used for this type of feature?
- What services/utilities already exist that I should use?
- What would break if I change this?

### 2.3 Read Existing Tests

```bash
# Find related tests
find . -type f -name "*.test.*" -o -name "*.spec.*" | xargs grep -l "[relevant terms]"
```

Understand:
- How similar features are tested
- Expected behaviors
- Edge cases already handled

### 2.4 Write Research Document

Create `docs/specs/[feature-name]/research.md`:

```markdown
# Research: [Feature Name]

## Date
[Current date]

## Requirements Summary
[Brief summary of what's being built]

---

## Product Context
[Relevant info from product.md]
- Product vision alignment
- Related features
- User personas affected

---

## Technical Context
[Relevant info from tech.md]
- Stack components involved
- Conventions to follow
- Commands to use

---

## Codebase Analysis

### Relevant Files
| File | Purpose | Key Functions |
|------|---------|---------------|
| [path] | [what it does] | [functions to use/extend] |

### Existing Patterns
- [Pattern 1]: Used in [file], should follow for [reason]
- [Pattern 2]: [description]

### Services/Utilities to Reuse
- [Service]: [what it does, how to use]
- [Utility]: [what it does, how to use]

### Integration Points
- [System A]: Will need to integrate via [method]
- [System B]: [description]

---

## Test Patterns
- Similar features tested with: [approach]
- Test utilities available: [list]
- Coverage expectations: [from quality-gates.md]

---

## Risks & Considerations
- [Risk 1]: [description and mitigation]
- [Risk 2]: [description and mitigation]

---

## Recommendations for Implementation
- Use [existing utility] for [purpose]
- Follow [pattern] from [file]
- Avoid [anti-pattern] because [reason]
```

**This document becomes input for the planning phase.**

---

## Phase 1.5: Resolve Ambiguities (CRITICAL — DO NOT SKIP)

Based on research findings, identify ALL underspecified aspects before designing:

1. Review the research document and original requirements
2. Identify gaps: edge cases, error handling, integration points, scope boundaries, backward compatibility, performance needs

**If BUILDWRIGHT_AUTO_APPROVE is not set to `false` (default — autonomous mode):**
- Make your best judgment for each ambiguity based on research findings
- Document each decision and rationale in the research document under "Assumptions Made"
- Prefer the simpler, safer, more conventional choice
- Proceed directly to specification

**If BUILDWRIGHT_AUTO_APPROVE=false (interactive mode):**
- Present all questions to the user in a clear, organized list
- Wait for answers before proceeding to specification

This phase prevents the #2 failure mode: building the wrong thing because requirements were ambiguous.

---

## Phase 3: Generate Technical Specification

Create `docs/specs/[feature-name]/spec.md`

**The spec must reference and build upon research.md findings.**

### Section 1: Overview
- Problem Statement
- Success Metrics (measurable)
- Scope (in/out)

### Section 2: Design Principles Applied
- How KISS, YAGNI, no premature optimization are applied
- **Reference existing patterns from research**

### Section 3: Approaches Considered (CRITICAL)
- Design at least 2 approaches with different trade-off focuses:
  - **Minimal changes**: Smallest change, maximum reuse of existing code
  - **Clean architecture**: Best maintainability and elegant abstractions
  - **Pragmatic balance** (optional): Speed + quality middle ground
- For each: pros/cons/complexity/estimate
- **Autonomous mode**: Pick the best approach, document rationale
- **Interactive mode**: Present recommendation and let user choose
- **Reference existing patterns and code from research**

### Section 4: User Journeys
- Primary flows with diagrams
- Edge cases and handling

### Section 5: Technical Design
- Architecture diagram
- Data model (if applicable)
- API design (if applicable)
- **Reference existing services/utilities from research**

### Section 6: What We're NOT Doing
- Explicit list of excluded features
- Why each is excluded

### Section 7: Security Considerations
- Input validation, auth, data protection

### Section 8: Testing Strategy
- **Follow test patterns identified in research**
- What to test, what NOT to test

### Section 9: Implementation Milestones
- Each: independently deployable, 2-4 hours, clear done criteria
- **Reference specific files/functions from research**

### Section 10: Open Questions & Assumptions

---

## Phase 4: Validate Specification (AUTO)

Adopt Staff Engineer persona from `.buildwright/agents/staff-engineer.md`.

Review the spec for:
- Does it leverage existing patterns from research?
- Problem clearly understood?
- Approaches genuinely evaluated?
- Design principles applied?
- Risks identified?
- Milestones realistic?

Act on findings by severity:
- **Critical Issues**: Fix in spec and re-validate. These block approval.
- **Recommendations**: Fix if straightforward (< 5 min). Otherwise note as TODO in spec — address during implementation.
- **Observations**: Acknowledge and move on. Do not modify spec.

If zero critical issues remain → proceed to approval.

---

## Phase 5: Request Human Approval

Present summary:

```
═══════════════════════════════════════════════════════════════
SPECIFICATION COMPLETE
═══════════════════════════════════════════════════════════════

Feature: [name]
Research: docs/specs/[feature-name]/research.md
Spec: docs/specs/[feature-name]/spec.md

RESEARCH FINDINGS
─────────────────
• Existing patterns to follow: [list]
• Services to reuse: [list]
• Key risks identified: [list]

APPROACH CHOSEN
───────────────
[Brief description]

Considered [N] alternatives. Chose this because:
• [Reason 1]
• [Reason 2]

MILESTONES
──────────
1. [Milestone 1] (~X hrs)
2. [Milestone 2] (~X hrs)
3. [Milestone 3] (~X hrs)

Total: ~[X] hours

STAFF ENGINEER REVIEW: ✅ Passed

═══════════════════════════════════════════════════════════════

Please review:
• docs/specs/[feature-name]/research.md (codebase analysis)
• docs/specs/[feature-name]/spec.md (implementation plan)

Reply "approved" to proceed with implementation.
Reply with feedback to revise.
═══════════════════════════════════════════════════════════════
```

**If BUILDWRIGHT_AUTO_APPROVE is not set to `false` (default — autonomous mode):**
- Commit spec to git (audit trail): `docs: add spec for [feature-name]`
- Proceed directly to Phase 6: Implement

**If BUILDWRIGHT_AUTO_APPROVE=false (interactive mode):**
- STOP and wait for human to say "approved".

---

## Phase 6: Implement (After Approval)

### Detect Implementation Mode

**Single-domain or small scope** → Sequential implementation (below)

**Multi-domain (3+ independent components, 8+ hours, crosses layer boundaries)** → Recommend Claw Architecture:

```
╔═══════════════════════════════════════════════════════════════╗
║  MULTI-DOMAIN FEATURE DETECTED                                ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  This feature touches [N] domains: [list]                     ║
║                                                               ║
║  Recommendation: Use /bw-claw for multi-agent execution       ║
║                                                               ║
║  Benefits:                                                    ║
║  • Each domain gets a specialist agent (claw)                 ║
║  • Interface contracts prevent integration failures           ║
║  • Parallel execution where possible                          ║
║                                                               ║
║  /bw-claw "[feature description]"                             ║
║                                                               ║
║  Or say "continue" to proceed with single-agent mode.         ║
╚═══════════════════════════════════════════════════════════════╝
```

If parallel selected, $ARGUMENTS.parallel set, or user says "claw":
- Switch to `/bw-claw` pipeline
- STOP this command

### Sequential Implementation (Default)

For each milestone:

1. **Write tests first (TDD)**
   - Follow test patterns from research.md
   - Create failing tests
   - Commit: `test: add tests for [milestone]`

2. **Implement**
   - Follow patterns identified in research.md
   - Use existing services/utilities discovered
   - Write minimal code to pass tests
   - Remember: KISS, YAGNI

3. **Verify (with retry)**
   ```bash
   [typecheck] [lint] [test] [build]
   ```
   - If fails → Fix and retry (up to BUILDWRIGHT_AGENT_RETRIES attempts, default 2)
   - If same error repeats → Not making progress — handle failure (see below)
   - If still failing after retries → Handle failure:
     - **Autonomous** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): Commit completed milestones, push branch, create PR with failure summary (see BUILDWRIGHT.md template), exit(1).
     - **Interactive** (`BUILDWRIGHT_AUTO_APPROVE=false`): STOP and report blocker.

4. **If ALL pass:** Run milestone quality check, then commit.

### Milestone Quality Check

After each milestone passes verification, briefly self-review for:
- **Simplicity**: Is this the simplest solution? Any unnecessary complexity?
- **Correctness**: Any logic errors or missed edge cases in the new code?
- **Conventions**: Does the new code follow established project patterns?

Only flag HIGH SIGNAL issues (confidence ≥ 80). Fix issues autonomously — don't gold-plate, ship what works.

5. **Commit:** `feat([scope]): [description]`

---

## Phase 7: Ship

Run `/bw-ship` which chains:
1. verify → typecheck, lint, test, build
2. security → OWASP, SAST, secrets, deps
3. review → Staff Engineer code review
4. release → commit, push, PR

`/bw-ship` handles autonomous failure internally — if any step fails in autonomous mode, it commits completed work, pushes, creates a failed PR, and exits(1). See ship.md for details.

---

## Final Report

```
═══════════════════════════════════════════════════════════════
FEATURE COMPLETE
═══════════════════════════════════════════════════════════════

Feature: [name]
Branch: feature/[feature-name]
PR: [URL]

ARTIFACTS
─────────
• Research: docs/specs/[feature-name]/research.md
• Spec: docs/specs/[feature-name]/spec.md

PIPELINE STATUS
───────────────
✅ Research Complete
✅ Spec Generated
✅ Spec Reviewed (Staff Engineer)
✅ Human Approved
✅ Implemented (TDD)
✅ Verified
✅ Security Reviewed
✅ Code Reviewed (Staff Engineer)
✅ Shipped

Quality gates running in CI. Will auto-merge on pass.
═══════════════════════════════════════════════════════════════
```
