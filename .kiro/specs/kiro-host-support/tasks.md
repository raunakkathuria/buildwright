# Implementation Plan: kiro-host-support

## Overview

The implementation language is **Bash** — the feature extends the existing
`.buildwright/scripts/sync-agents.sh` shell script and edits the Markdown docs it
governs. All work is strictly additive: the new Kiro target is appended after the Codex
section, reuses existing helpers (`strip_frontmatter`, `sed_inplace`, `CHECK_ONLY`,
`SYNC_NEEDED`), and never modifies existing target functions so their output stays
byte-identical (P5, Requirement 7).

Tests use a shell-assert / bats-style harness (POSIX `sh`/`bash`, `diff`, `mktemp`) with
committed fixtures and golden outputs, validating correctness properties P1–P6. Test
sub-tasks are marked optional with `*`; the core script and doc edits are not.

## Tasks

- [x] 1. Set up Kiro-sync test scaffolding and fixtures
  - [x]* 1.1 Create the test harness and canonical fixtures
    - Add a runnable test script (e.g. `.buildwright/scripts/test/test-sync-kiro.sh`) using plain `bash` + `diff` asserts (bats-compatible layout), no new dependencies (_Requirements: 10.1, 10.2_)
    - Create a minimal fixture `.buildwright/` tree under a temp/fixture root covering all five categories: `framework/*.md`, `steering/*.md`, `codebase/*.md`, `commands/bw-*.md`, `agents/*.md`, plus a `README.md`/`TEMPLATE.md` to exercise exclusion, and a file with front-matter `description`, one with only a heading, and one with neither
    - Add a fixture source file containing both `@@.buildwright/<subdir>/<name>.md` references (all five subdirs) and bare `.buildwright/...` references for the rewrite test
    - Seed a `.kiro/steering/project-x.md` non-`bw-*` fixture for the non-clobber test
    - _Requirements: 1.4, 1.5, 4.1, 4.2_

- [x] 2. Implement Kiro helper functions in sync-agents.sh
  - [x] 2.1 Implement `kiro_frontmatter` and `purge_bw_namespace` helpers
    - Add `kiro_frontmatter INCLUSION DESCRIPTION` emitting a `---`/`inclusion:`/`description:`/`---` block to stdout as the first bytes (offset 0) (_Requirements: 5.1, 5.2, 5.3_)
    - Add `purge_bw_namespace GLOB` that deletes only files matching a `bw-*` glob inside `.kiro/steering/`/`.kiro/hooks/`, guarded so it is a no-op in `CHECK_ONLY` mode and `set -e` safe (_Requirements: 3.1, 3.4, 3.5_)
    - Place both in the Kiro section appended after the Codex block; do not modify any existing helper (_Requirements: 7.2, 7.3_)
    - _Requirements: 5.1, 5.2, 5.3, 3.4, 3.5_

  - [ ]* 2.2 Write unit tests for `kiro_frontmatter` and `purge_bw_namespace`
    - Assert front-matter is emitted at byte offset 0 with `inclusion` ∈ {always, manual} and a single `description` field (**Validates: P6, Requirements 5.1, 5.2**)
    - Assert `purge_bw_namespace` deletes only `bw-*` matches and never a seeded non-`bw-*` file (**Validates: P3, P1, Requirements 3.4, 3.5**)
    - _Requirements: 3.4, 3.5, 5.1, 5.2_

  - [x] 2.3 Implement `kiro_ref_rewrite`
    - Add `kiro_ref_rewrite FILE` iterating the fixed subdir→prefix map (`framework/`→`bw-framework-`, `steering/`→`bw-steering-`, `codebase/`→`bw-codebase-`, `agents/`→`bw-agent-`, `commands/`→`bw-command-`) (_Requirements: 4.1_)
    - Rewrite each `@@.buildwright/<subdir>/<name>.md` to `#[[file:.kiro/steering/<prefix><name>.md]]` via `sed_inplace` only, leaving bare `.buildwright/` refs and all other bytes untouched (_Requirements: 4.2, 4.3, 10.3_)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 10.3_

  - [ ]* 2.4 Write property test for `kiro_ref_rewrite`
    - **Property P4: Ref integrity — no generated file contains a literal `@@.buildwright/`**
    - Run against the mixed-reference fixture; assert every `@@` ref for a mapped subdir is rewritten to the exact `#[[file:...]]` form, bare `.buildwright/` refs are byte-preserved, and no other bytes change (**Validates: P4, Requirements 4.2, 4.3, 4.4**)
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 3. Implement Kiro sync generation functions
  - [x] 3.1 Implement `sync_kiro_steering`
    - Add `sync_kiro_steering SRC_DIR NAME_PREFIX INCLUSION`: early-return when `SRC_DIR` absent; in write mode `purge_bw_namespace` for this prefix then `mkdir -p .kiro/steering` (_Requirements: 1.4, 3.4_)
    - For each sorted `*.md`, skip case-insensitive `README`/`TEMPLATE`, derive description (front-matter `description`, else first heading, else base name / empty), strip source front-matter via `strip_frontmatter`, emit `kiro_frontmatter` + body to `<prefix><base>.md`, then apply `kiro_ref_rewrite` (_Requirements: 1.1, 1.5, 1.6, 1.7, 1.8, 2.3, 5.4, 5.6_)
    - Honour `CHECK_ONLY`: build expected output in a temp file, compare byte-for-byte, print `OUT OF SYNC:`/`MISSING:` and set `SYNC_NEEDED=true` on drift, modifying nothing (_Requirements: 3.6, 6.1, 6.2_)
    - Detect same-category output-name collisions and halt that category with a non-zero error identifying the conflicting sources, leaving prior output unchanged (_Requirements: 2.6_)
    - _Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 2.1, 2.3, 5.4, 5.6, 6.1, 6.2, 2.6_

  - [ ]* 3.2 Write unit tests for `sync_kiro_steering` generation rules
    - Assert README/TEMPLATE exclusion, prefix+base naming, description precedence (front-matter → heading → base name), and source front-matter removal from the body (_Requirements: 1.5, 1.6, 1.7, 1.8, 2.3, 5.4_)
    - Assert `inclusion: always` for framework/steering/codebase sources and the collision halt behaviour (**Validates: P6, Requirements 2.1, 2.6**)
    - _Requirements: 1.5, 1.6, 1.7, 1.8, 2.1, 2.3, 2.6, 5.4_

  - [x] 3.3 Implement `sync_kiro_command_dir`
    - Add `sync_kiro_command_dir SRC_DIR NAME_PREFIX` that delegates to `sync_kiro_steering SRC_DIR NAME_PREFIX "manual"` so commands/agents become `inclusion: manual` docs referenceable as `#bw-command-<name>` / `#bw-agent-<name>` (_Requirements: 2.2, 2.4_)
    - _Requirements: 2.2, 2.4_

  - [x] 3.4 Implement `sync_kiro_hooks`
    - Add `sync_kiro_hooks`: in write mode `purge_bw_namespace .kiro/hooks/bw-*.kiro.hook`; no-op when `.buildwright/hooks/` is absent; otherwise `mkdir -p .kiro/hooks` and copy each `*.json` manifest to `.kiro/hooks/bw-<base>.kiro.hook` (_Requirements: 1.2, 1.4, 3.4_)
    - Keep `set -e` safe and scoped strictly to the `bw-*` hook glob (_Requirements: 3.1, 3.5_)
    - _Requirements: 1.2, 1.4, 3.1, 3.4, 3.5_

- [x] 4. Wire the Kiro target into the script and update its self-documentation
  - [x] 4.1 Add the top-level Kiro block, header comment, and result output
    - Append the "5. .buildwright/ → .kiro/" section after the Codex block with calls: `sync_kiro_steering .buildwright/framework bw-framework- always`, `.../steering bw-steering- always`, `.../codebase bw-codebase- always`, `sync_kiro_command_dir .buildwright/commands bw-command-`, `.../agents bw-agent-`, `sync_kiro_hooks` (_Requirements: 1.1, 2.1, 2.2, 7.2_)
    - Add generated Kiro output paths to the script header comment and to the final "Sync complete" result summary (_Requirements: 9.5_)
    - Ensure a Kiro-target error yields a non-zero exit while leaving existing target output byte-identical (_Requirements: 7.5_)
    - _Requirements: 1.1, 2.1, 2.2, 7.2, 7.5, 9.5_

- [x] 5. Checkpoint - core script wired
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Add the Kiro column to the capability table
  - [x] 6.1 Edit `.buildwright/framework/capability.md`
    - Insert exactly one Kiro column immediately after OpenCode and before Fallback, with a non-empty native value in every capability row (_Requirements: 8.1, 8.2, 8.5_)
    - In the command-invocation row, document the `#bw-command-<name>` manual-steering-doc fallback, and add the note that this preserves the real Buildwright command prose rather than substituting Kiro's interpretation (_Requirements: 8.3, 8.4_)
    - Leave existing Claude/Codex/Cursor/OpenCode/Fallback cell values byte-identical (_Requirements: 7.4_)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 7.4_

- [x] 7. Gitignore generated output and update project documentation
  - [x] 7.1 Add scoped `.gitignore` entries
    - Append `.kiro/steering/bw-*.md` and `.kiro/hooks/bw-*.kiro.hook` so generated files report no `git status` change while non-`bw-*` project steering docs stay tracked (_Requirements: 9.1, 9.2, 9.3_)
    - _Requirements: 9.1, 9.2, 9.3_

  - [x] 7.2 Update `AGENTS.md` Project Structure
    - Add a `.kiro/` line describing it as generated, gitignored output produced by the sync (_Requirements: 9.4_)
    - _Requirements: 9.4_

- [ ] 8. Validate correctness properties and regression isolation
  - [ ]* 8.1 Golden-file test of full Kiro generation
    - Run the full sync against the fixtures; compare generated `.kiro/steering/bw-*.md` and `.kiro/hooks/bw-*.kiro.hook` (front-matter + body + rewritten refs) to committed golden outputs (**Validates: P4, P6, Requirements 1.1, 5.1, 5.2**)
    - _Requirements: 1.1, 5.1, 5.2_

  - [ ]* 8.2 Non-clobber and namespace-containment test
    - **Property P1: Non-clobber — no committed non-`bw-*` file under `.kiro/steering/` is created, modified, or deleted**
    - **Property P3: Namespace containment — every path written or deleted matches `bw-*`**
    - Run the sync with the seeded `project-x.md`; assert it is byte-identical afterward and that all writes/deletes are within the BW namespace (**Validates: P1, P3, Requirements 3.1, 3.2, 3.3, 3.5**)
    - _Requirements: 3.1, 3.2, 3.3, 3.5_

  - [ ]* 8.3 Idempotency and `--check` test
    - **Property P2: Idempotent — running the sync twice yields no diff; `--check` after a sync exits 0**
    - Sync; sync again and assert a byte-identical `.kiro/` tree; run `sync-agents.sh --check` and assert exit 0 with `SYNC_NEEDED=false`; mutate one generated file and assert `--check` reports that file and exits non-zero (**Validates: P2, Requirements 6.3, 6.4, 6.5, 6.6**)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [ ]* 8.4 Regression snapshot of existing targets
    - **Property P5: Regression isolation — `.claude` / `.opencode` / `.cursor` / `.agents` outputs are byte-identical before and after adding the Kiro target**
    - Snapshot the existing target trees, run the full sync, and assert zero diff (**Validates: P5, Requirements 7.1, 7.3**)
    - _Requirements: 7.1, 7.3_

- [x] 9. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional test sub-tasks and can be skipped for a faster MVP; core script and doc edits are not optional.
- The implementation is Bash; every task reuses existing helpers and adds no new runtime dependency (Requirement 10).
- Property tests map directly to the design's P1–P6; each is its own sub-task placed near the code it validates.
- Checkpoints ensure incremental validation before the doc edits and before completion.
- Every task writing to `sync-agents.sh` is scheduled in a distinct wave to avoid edit conflicts (see dependency graph).

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "6.1", "7.1", "7.2"] },
    { "id": 2, "tasks": ["2.2", "2.3"] },
    { "id": 3, "tasks": ["2.4", "3.1"] },
    { "id": 4, "tasks": ["3.2", "3.3"] },
    { "id": 5, "tasks": ["3.4"] },
    { "id": 6, "tasks": ["4.1"] },
    { "id": 7, "tasks": ["8.1", "8.2", "8.3", "8.4"] }
  ]
}
```
