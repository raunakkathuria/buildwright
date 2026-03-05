---
name: bw-analyse
description: Analyse the codebase and write structured docs to .buildwright/codebase/. Updates tech.md with discovered stack and architecture.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - Edit
---

<objective>
Analyse the existing codebase and produce structured reference documents in
`.buildwright/codebase/`. Then update `.buildwright/steering/tech.md` with a summary
so every session starts with real project context instead of template placeholders.
</objective>

<when_to_use>
Run /bw-analyse when:
- Starting on an unfamiliar or brownfield codebase
- .buildwright/codebase/ is missing or stale
- tech.md still contains template placeholders
- Before /bw-new-feature or /bw-claw on an existing project

Skip when:
- Greenfield project with no code yet
- .buildwright/codebase/ was generated this session
</when_to_use>

<process>
1. If `.buildwright/codebase/` already has files, ask: refresh or skip?
2. Create `.buildwright/codebase/` if it does not exist
3. Explore and write STACK.md
   - Read package.json / Cargo.toml / go.mod / pyproject.toml (whichever exists)
   - Identify language, runtime, package manager, key frameworks, dependencies
   - Scan for external service imports (APIs, auth, storage, monitoring)
   - Write `.buildwright/codebase/STACK.md`
4. Explore and write ARCHITECTURE.md
   - Map directory structure (excluding node_modules, .git, build output)
   - Identify entry points, layers, data flow, error handling strategy
   - Note where to add new features, components, and tests
   - Write `.buildwright/codebase/ARCHITECTURE.md`
5. Explore and write CONVENTIONS.md
   - Read linting/formatting configs (.eslintrc, .prettierrc, biome.json, etc.)
   - Sample 5-10 source files for naming patterns, import style, error handling
   - Identify test framework, test file locations, mocking patterns
   - Write `.buildwright/codebase/CONVENTIONS.md`
6. Explore and write CONCERNS.md
   - Grep for TODO/FIXME/HACK comments
   - Find large files (potential complexity)
   - Note missing tests, security gaps, fragile areas
   - Write `.buildwright/codebase/CONCERNS.md`
7. Update `.buildwright/steering/tech.md`:
   - Replace placeholder in ## Stack with discovered languages, runtime, frameworks
   - Replace placeholder in ## Architecture with 3-5 line summary
   - Replace placeholder in ## Code Patterns with top 3 patterns from CONVENTIONS.md
   - Replace placeholder in ## Dependencies with key packages and their purpose
   - Leave ## Project Commands unchanged if already populated; populate if still placeholder
8. Run `scripts/sync-agents.sh` to propagate codebase docs to all tool directories
9. Commit: `chore: add codebase analysis to .buildwright/codebase/`
10. Report: list 4 docs with line counts, summarise key findings, suggest next step
</process>

<forbidden_files>
NEVER read or include contents from:
- .env, .env.*, *.env — environment variables
- credentials.*, secrets.*, *secret*, *credential*
- *.pem, *.key, *.p12 — certificates and private keys
- id_rsa*, id_ed25519* — SSH keys
- .npmrc, .pypirc, .netrc — auth tokens
- Any file that appears to contain API keys or passwords

Note their existence only. Never quote their contents.
</forbidden_files>

<success_criteria>
- [ ] .buildwright/codebase/ contains STACK.md, ARCHITECTURE.md, CONVENTIONS.md, CONCERNS.md
- [ ] tech.md placeholder sections replaced with real content
- [ ] No secrets or credentials in any written file
- [ ] Changes committed
</success_criteria>
