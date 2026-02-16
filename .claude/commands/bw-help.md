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
/bw-quick <task>          Fast path for bug fixes, small tasks, config changes
/bw-ship                  Quality gates + release: verify → security → review → push → PR
/bw-verify                Quick checks: typecheck, lint, test, build
/bw-help                  Show this command list

╔═══════════════════════════════════════════════════════════════╗
║                      QUICK REFERENCE                          ║
╚═══════════════════════════════════════════════════════════════╝

NEW FEATURE (full workflow):
  /bw-new-feature "Add user authentication"
  > [Claude researches, generates spec, validates]
  > approved
  > [Claude implements and ships]

BUG FIX (fast path):
  /bw-quick "Fix the login timeout bug"
  > [Claude fixes, verifies, commits]

SHIP EXISTING WORK:
  /bw-ship "feat(auth): add OAuth2 support"
  > [Claude runs verify → security → review → release]

╔═══════════════════════════════════════════════════════════════╗
║                         TIPS                                  ║
╚═══════════════════════════════════════════════════════════════╝

• Use /bw-new-feature for anything that needs planning
• Use /bw-quick for clear, bounded tasks
• Verify retries 2x automatically; security/review stops immediately
• Say "approved" to proceed after spec review
• Say feedback to revise: "Break milestone 2 into smaller chunks"

For more details, see BUILDWRIGHT.md
```
