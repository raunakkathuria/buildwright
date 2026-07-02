# Changelog

## 0.0.18

- Breaking change: Buildwright-owned support scripts moved from the consuming
  project's root `scripts/` into `.buildwright/scripts/` (sync-agents.sh,
  validate-docs.sh, install-hooks.sh, and the git hooks). Buildwright no longer
  ships a `Makefile`, `README.md`, `.gitignore`, or `.env.example` into
  projects, and `setup.sh` no longer overwrites any existing file. Run
  `buildwright sync` (or `bash .buildwright/scripts/sync-agents.sh`) where you
  previously ran `make sync`. The git hooks call the sync script directly, so
  `make` is no longer required. Installers append a marker-guarded block of
  generated-dir entries to the project's `.gitignore` instead of replacing it.
  `buildwright update` migrates old installs automatically: it removes the
  pre-0.0.18 root `scripts/` files and Buildwright-shipped `Makefile` (anything
  customized is preserved) and reinstalls the hooks.
- Leaner distribution: the npm CLI (`buildwright init`/`update`/`sync`) is the
  single supported project install. Removed the `make
  global`/`claude`/`codex`/`opencode`/`openclaw` global-install targets and the
  generated `dist/` flow; the ClawHub skill now lives in a committed `clawhub/`
  folder that is uploaded as-is (version stamped by `make bump`). `setup.sh`
  downloads the repo tarball once and copies `.buildwright/` wholesale (no more
  hand-maintained file list), no longer ships `.claude/settings.json`, and
  exits early on an existing install.
- Steering is strictly project-owned on update: `buildwright update` only adds
  shipped steering files that are absent and never modifies existing ones
  (the SHA-256 managed-hash machinery is gone).
- Cursor rule descriptions are derived from each file's frontmatter
  `description:` or first heading instead of a hand-maintained registry in
  `sync-agents.sh`.
- The repo's release tooling (`bump-version.sh`, `release.sh`) moved to
  `cli/scripts/` alongside the npm pack scripts, so the only scripts directory
  is the shipped `.buildwright/scripts/` — the root `scripts/` folder is gone.
- Added `.buildwright/framework/tasks-to-issues.md`: the convention for turning
  an approved plan's tasks into tracked forge issues — a parent issue plus one
  child per unit of work, with stable IDs, idempotent re-runs (dedup by ID), and
  a remote guard. Optionally fans out across repos, linking children under one
  feature via a GitHub Project or GitLab Epic. `/bw-plan` prepares the
  issue-ready breakdown; the issues are created at the `/bw-work` handoff, never
  by `/bw-plan` itself.
- `/bw-work` now performs that handoff: when a task hands off a plan with an
  issue-ready breakdown, it creates the tracked issues (guarded, deduped) before
  implementation. `setup.sh` ships the new framework doc.
- Kept Buildwright forge-agnostic: `/bw-ship` documents `gh` and `glab`
  equivalently and speaks in change-request (PR/MR) terms.
- Repo hygiene for public consumption: removed the Spec Kit test install
  (`.specify/`, `specs/`) and a leftover design-tool artifact
  (`docs/superpowers/`); replaced an internal service name in the spec with a
  generic reference.

## 0.0.17

- Generated commands now carry a `version:` frontmatter stamp (sourced from
  `cli/package.json`), so an installed `bw-*` command set reveals when it is
  stale. `make bump` updates the stamp in canonical `.buildwright/commands/*.md`
  and `make sync` propagates it to `.claude/`, `.opencode/`, and Codex `skills/`.
- `/bw-plan` now writes its deliverable with a single decisive native file write
  (no "writing now…" narration, incremental for large plans, clear error + stop
  on write failure) — fixes the plan-write stall.
- `/bw-plan` ends with an explicit handoff: it recommends running `/bw-work` and,
  when continuing, invokes the real command via native command invocation rather
  than re-enacting it from memory. No more free-text "Want me to proceed?".
- Added `.buildwright/framework/` for Buildwright-owned behaviour docs, kept
  separate from project-owned `.buildwright/steering/`: `autonomy.md` (single
  behaviour + auto-continue), `capability.md` (prefer host-native capabilities
  with fallbacks), and `findings.md` (report-upstream / before-production
  deferral convention). Framework docs are refreshed on update; steering is
  preserved. Commands now lean on native task tracking, file writes, and command
  invocation.
- Removed the `BUILDWRIGHT_AGENT_RETRIES` environment variable. It was
  unenforced (no script read it) and presented a configurable retry count that
  did nothing. The verify loop now stops on a progress-based condition — fix and
  re-run until the gate passes or progress stalls (the same failure recurs, or
  there is no diagnosable fix) — instead of a fixed number of attempts. Failure
  handoff (interactive → ask; unattended/CI → `[FAILED]` PR, exit non-zero) is
  unchanged.
- Breaking change: removed the `BUILDWRIGHT_AUTO_APPROVE` environment variable.
  It was unenforced (no script read it) and overloaded across `bw-plan`,
  `bw-work`, `bw-ship`, and `bw-analyse`. Buildwright now has a single autonomy
  behaviour (see `.buildwright/framework/autonomy.md`): execute autonomously,
  pause only on a decision genuinely the human's to make, stop when blocked. On
  failure the execution context is inferred (interactive → ask; unattended/CI →
  preserve work, open a `[FAILED]` PR, exit non-zero) instead of read from a
  flag.

## 0.0.16

- Made `AGENTS.md` the single canonical instruction file (committed,
  hand-maintained). `CLAUDE.md` is now a pointer stub to it; neither is
  generated by `make sync`.
- Added global install: `make global` installs the workflow for every supported
  tool at once, plus a new `make claude` target (commands + agents into
  `~/.claude/`) alongside the existing `make codex`/`opencode`/`openclaw`.
- Documented Codex project instructions via `AGENTS.md` and all global-install
  options in the README.
- Gave the Staff Engineer and Security Engineer personas `name`/`description`
  frontmatter so they register as valid agents in each tool. `/bw-work` and
  `/bw-ship` reviews read them from a project's `.buildwright/agents/`, falling
  back to `~/.claude/agents/` for a global install without a project config.
- Fixed `make sync` to strip a source file's own frontmatter before generating
  Cursor `.mdc` rules, removing a duplicate frontmatter block from generated
  command and agent rules.

## 0.0.13

- Breaking change: simplified Buildwright to five public commands:
  `/bw-plan`, `/bw-work`, `/bw-verify`, `/bw-ship`, and `/bw-analyse`.
- Replaced `/bw-new-feature`, `/bw-quick`, and `/bw-claw` with `/bw-work`.
- Removed claws, worktree skills, task templates, requirements templates, and
  placeholder steering docs.
- Added `.buildwright/steering/philosophy.md` as the default steering source
  for KISS, YAGNI, DRY, Red-Green-Refactor, and documentation discipline.
- Made steering discovery recursive so nested steering docs are picked up.
- Stopped installing Buildwright's own GitHub Actions workflow into downstream
  projects.
