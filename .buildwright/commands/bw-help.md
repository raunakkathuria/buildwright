---
name: bw-help
description: List all available Buildwright commands
---

## Buildwright Commands

```
╔═══════════════════════════════════════════════════════════════╗
║                 BUILDWRIGHT COMMANDS                          ║
╚═══════════════════════════════════════════════════════════════╝

WORKFLOW
────────
/bw-new-feature <desc>   Full pipeline: research → spec → approve → build → ship
/bw-claw <feature>       Multi-agent: architect decomposes → claws execute per domain
/bw-quick <task>         Fast path for bug fixes, small tasks, config changes
/bw-ship                 Quality gates + release: verify → security → review → push → PR
/bw-verify               Quick checks: typecheck, lint, test, build
/bw-help                 Show this command list

╔═══════════════════════════════════════════════════════════════╗
║                      QUICK REFERENCE                          ║
╚═══════════════════════════════════════════════════════════════╝

NEW FEATURE (single domain):
  /bw-new-feature "Add user authentication"
  > [Agent researches, generates spec, validates]
  > approved
  > [Agent implements and ships]

CROSS-DOMAIN FEATURE (multi-agent):
  /bw-claw "Add profile photo upload"
  > [Architect decomposes into claw tasks]
  > [DB Claw: migration, API Claw: endpoint, UI Claw: component]
  > [Architect integrates and ships]

BUG FIX (fast path):
  /bw-quick "Fix the login timeout bug"
  > [Agent fixes, verifies, commits]

SHIP EXISTING WORK:
  /bw-ship "feat(auth): add OAuth2 support"
  > [Agent runs verify → security → review → release]

╔═══════════════════════════════════════════════════════════════╗
║                    WHEN TO USE WHAT                            ║
╚═══════════════════════════════════════════════════════════════╝

  Single domain, needs planning     → /bw-new-feature
  Crosses multiple domains/layers   → /bw-claw
  Small task, clear scope           → /bw-quick
  Code ready, need quality gates    → /bw-ship
  Quick check during development    → /bw-verify

╔═══════════════════════════════════════════════════════════════╗
║                  CLAW ARCHITECTURE                             ║
╚═══════════════════════════════════════════════════════════════╝

              🧠 Architect (Brain)
                   │
         ┌─────────┼─────────┐
         │         │         │
       🎨 UI    ⚙️ API    🗄️ DB
       Claw     Claw     Claw

  Claws are domain-specialist agents in .buildwright/claws/
  Available: frontend.md, backend.md, database.md
  Add your own: copy .buildwright/claws/TEMPLATE.md

╔═══════════════════════════════════════════════════════════════╗
║                         TIPS                                  ║
╚═══════════════════════════════════════════════════════════════╝

• Use /bw-new-feature for anything that needs planning
• Use /bw-claw when feature crosses domain boundaries
• Use /bw-quick for clear, bounded tasks
• Verify retries 2x automatically; security/review stops immediately
• Say "approved" to proceed after spec/plan review
• Say feedback to revise: "Break milestone 2 into smaller chunks"

For more details, see BUILDWRIGHT.md
```
