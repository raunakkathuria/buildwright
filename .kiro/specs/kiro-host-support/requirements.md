# Requirements Document

## Introduction

This feature adds Kiro as a first-class supported host in the Buildwright framework. The Buildwright
sync script (`.buildwright/scripts/sync-agents.sh`) already generates host-native artifacts for
Claude Code, OpenCode, Cursor, and Codex from the canonical `.buildwright/` source. This feature
extends that script with a Kiro generation target that produces Kiro-native steering docs and
optional agent hooks under `.kiro/`, and adds a Kiro column to the capability table in
`.buildwright/framework/capability.md`.

All generated Kiro output is namespaced with a `bw-` prefix and gitignored so it never clobbers the
team's existing committed `.kiro/steering/*.md` project docs. The change is strictly additive: the
existing Claude/OpenCode/Cursor/Codex targets keep byte-identical output, so the change is suitable
for an upstream PR to the Buildwright repository.

## Glossary

- **Kiro_Sync**: The new Kiro generation target added to `sync-agents.sh` (the `sync_kiro_*`
  functions) that reads canonical `.buildwright/` sources and writes Kiro-native artifacts.
- **Sync_Script**: The overall `.buildwright/scripts/sync-agents.sh` script, including all existing
  host targets and the new Kiro_Sync target.
- **Canonical_Source**: The tool-agnostic source of truth under `.buildwright/`
  (`framework/`, `steering/`, `codebase/`, `commands/`, `agents/`, and optional `hooks/`).
- **Steering_Doc**: A Kiro steering markdown file under `.kiro/steering/` that begins with a YAML
  front-matter block containing an `inclusion` field.
- **Inclusion_Mode**: The Kiro steering front-matter field value controlling load behaviour; one of
  `always` (auto-loaded every session) or `manual` (invoked on demand via `#<name>` in chat).
- **BW_Namespace**: The set of generated file paths owned by Kiro_Sync, matching
  `.kiro/steering/bw-*.md` or `.kiro/hooks/bw-*.kiro.hook`.
- **Project_Steering_Doc**: A committed, project-owned file under `.kiro/steering/` that does not
  begin with the `bw-` prefix (e.g. `clickup-context.md`, `formance-reference.md`).
- **Read_Marker**: The `@@.buildwright/` reference form in a Canonical_Source file, meaning "resolve
  to the host-specific location".
- **Kiro_File_Reference**: A Kiro cross-file reference of the form `#[[file:<path>]]`.
- **Check_Mode**: The `--check` invocation of the Sync_Script that verifies sync state without
  modifying the filesystem and reports drift.
- **Existing_Targets**: The generated output trees for the previously supported hosts
  (`.claude/`, `.opencode/`, `.cursor/rules/`, `.agents/`).
- **Capability_Table**: The host-capability mapping table in `.buildwright/framework/capability.md`.

## Requirements

### Requirement 1: Generate Kiro-native steering artifacts from canonical source

**User Story:** As a Buildwright user working in Kiro, I want the sync script to generate Kiro-native steering docs from the canonical `.buildwright/` source, so that Buildwright's behaviour and commands are available to Kiro without maintaining a separate Kiro configuration.

#### Acceptance Criteria

1. WHEN the Sync_Script is run in write mode, THE Kiro_Sync SHALL generate Steering_Docs under `.kiro/steering/` from the Canonical_Source directories `framework`, `steering`, `codebase`, `commands`, and `agents`, and SHALL prefix each generated Steering_Doc name with the BW_Namespace so that generated docs are distinguishable from user-authored Kiro steering docs.
2. WHEN the Sync_Script is run in write mode AND a `.buildwright/hooks/` directory exists, THE Kiro_Sync SHALL generate hook files under `.kiro/hooks/` from the hook manifests in that directory.
3. WHEN the Sync_Script is run in write mode more than once against the same Canonical_Source, THE Kiro_Sync SHALL overwrite the previously generated BW_Namespace-prefixed Steering_Docs and hook files so that the output matches the current Canonical_Source with no stale generated artifacts remaining.
4. WHERE a Canonical_Source directory is absent (for example `codebase` or `hooks`), THE Kiro_Sync SHALL skip that directory and generate no Steering_Docs or hook files for it.
5. WHEN generating Steering_Docs from a Canonical_Source directory, THE Kiro_Sync SHALL exclude every source file whose base name, compared case-insensitively and ignoring file extension, equals `README` or `TEMPLATE`.
6. WHEN generating a Steering_Doc from a Canonical_Source file that contains a front-matter description, THE Kiro_Sync SHALL set the generated front-matter `description` to that source front-matter description value.
7. WHEN generating a Steering_Doc from a Canonical_Source file that has no front-matter description, THE Kiro_Sync SHALL set the generated front-matter `description` to the text of the source file's first markdown heading.
8. IF a Canonical_Source file selected for generation has neither a front-matter description nor any markdown heading, THEN THE Kiro_Sync SHALL set the generated front-matter `description` to the source file's base name and continue generating the remaining Steering_Docs.

### Requirement 2: Map canonical categories to correct inclusion modes and name prefixes

**User Story:** As a Buildwright user in Kiro, I want framework and steering content auto-loaded and commands and agents available on demand, so that fixed behaviour is always active while command personas stay opt-in.

#### Acceptance Criteria

1. WHEN Kiro_Sync generates a Steering_Doc from a source file located under `.buildwright/framework`, `.buildwright/steering`, or `.buildwright/codebase`, THE Kiro_Sync SHALL set that Steering_Doc's Inclusion_Mode to `always`.
2. WHEN Kiro_Sync generates a Steering_Doc from a source file located under `.buildwright/commands` or `.buildwright/agents`, THE Kiro_Sync SHALL set that Steering_Doc's Inclusion_Mode to `manual`.
3. WHEN Kiro_Sync generates a Steering_Doc, THE Kiro_Sync SHALL name the output file as the concatenation of the fixed category prefix (`framework` maps to `bw-framework-`, `steering` maps to `bw-steering-`, `codebase` maps to `bw-codebase-`, `commands` maps to `bw-command-`, `agents` maps to `bw-agent-`), followed by the source file base name preserved unchanged with its original extension removed, followed by the `.md` extension.
4. WHERE a generated command Steering_Doc has Inclusion_Mode `manual`, THE Kiro_Sync SHALL produce a file whose `bw-command-<name>` identifier can be referenced in Kiro chat to invoke that Steering_Doc.
5. IF a source file is located outside the five mapped categories (`framework`, `steering`, `codebase`, `commands`, `agents`), THEN THE Kiro_Sync SHALL exclude that source file from Steering_Doc generation and SHALL NOT produce an output file for it.
6. IF two or more source files within the same mapped category would produce the same output file name, THEN THE Kiro_Sync SHALL halt generation for that collision and SHALL return an error indication identifying the conflicting source files, leaving previously generated Steering_Docs unchanged.

### Requirement 3: Namespace containment and non-clobber of project steering docs

**User Story:** As a team maintaining committed `.kiro/steering/` project docs, I want the sync to touch only its own generated files, so that our own steering docs are never overwritten or deleted.

#### Acceptance Criteria

1. WHEN the Sync_Script is run in write mode or Check_Mode, THE Kiro_Sync SHALL restrict every create, modify, and delete operation to files whose resolved paths reside within the BW_Namespace.
2. WHEN the Sync_Script is run in write mode or Check_Mode, THE Kiro_Sync SHALL perform zero create, modify, or delete operations on any path that resolves outside the BW_Namespace.
3. WHILE the Sync_Script is running, THE Kiro_Sync SHALL leave every Project_Steering_Doc byte-for-byte identical in content and unchanged in existence relative to its state immediately before the run.
4. WHEN the Kiro_Sync purges stale generated files before writing a given category, THE Kiro_Sync SHALL limit the purge to files that both match that category's `bw-` prefix glob and reside within the BW_Namespace.
5. IF a purge glob would match a path that resolves outside the BW_Namespace, THEN THE Kiro_Sync SHALL exclude that path from deletion and leave it unchanged.
6. WHILE the Sync_Script is running in Check_Mode, THE Kiro_Sync SHALL perform zero create, modify, or delete operations on the filesystem.

### Requirement 4: Rewrite canonical read-marker references into Kiro file references

**User Story:** As a Buildwright user in Kiro, I want cross-document references in generated steering docs to point at the generated Kiro files, so that referenced framework, steering, command, and agent docs resolve correctly inside Kiro.

#### Acceptance Criteria

1. WHEN a generated Steering_Doc contains one or more occurrences of a Read_Marker of the form `@@.buildwright/<subdir>/<name>.md` whose `<subdir>` maps to a defined prefix in the fixed category-to-prefix mapping, THE Kiro_Sync SHALL rewrite every such occurrence to the Kiro_File_Reference `#[[file:.kiro/steering/<prefix><name>.md]]` using that mapping.
2. WHEN a generated Steering_Doc contains a bare `.buildwright/` reference that is not immediately preceded by the `@@` Read_Marker prefix, THE Kiro_Sync SHALL preserve that reference byte-for-byte unchanged.
3. WHEN performing reference rewrites, THE Kiro_Sync SHALL leave every byte of the generated file other than the matched Read_Marker spans unchanged.
4. WHEN the Kiro_Sync completes in write mode, THE generated Steering_Docs SHALL contain zero remaining occurrences of the literal string `@@.buildwright/`.
5. IF a generated Steering_Doc contains a Read_Marker of the form `@@.buildwright/<subdir>/<name>.md` whose `<subdir>` has no entry in the fixed category-to-prefix mapping, THEN THE Kiro_Sync SHALL preserve that Read_Marker unchanged and report an error indicating the unmapped category, and SHALL NOT alter any other bytes of the file.

### Requirement 5: Front-matter validity for generated steering docs

**User Story:** As a Buildwright user in Kiro, I want every generated steering doc to carry a valid Kiro front-matter block, so that Kiro loads each doc with the intended inclusion behaviour.

#### Acceptance Criteria

1. WHEN the Kiro_Sync generates a Steering_Doc, THE Kiro_Sync SHALL write, as the first line of the file (byte offset 0, with no preceding whitespace, blank lines, or other content), an opening `---` delimiter, followed by the YAML front-matter block, followed by a closing `---` delimiter on its own line, before any body content.
2. THE front-matter block of every generated Steering_Doc SHALL contain exactly one `inclusion` field whose value is one of the two lowercase literals `always` or `manual`, and no other value.
3. WHEN the Kiro_Sync generates a Steering_Doc, THE front-matter block SHALL contain exactly one `description` field whose value is derived from the source per Requirement 1.5.
4. WHEN the Kiro_Sync writes the body of a Steering_Doc, THE Kiro_Sync SHALL remove the source file's original front-matter block (the leading content bounded by the first pair of `---` delimiter lines) so that it does not appear anywhere in the generated body.
5. IF the source file does not specify a resolvable Inclusion_Mode, THEN THE Kiro_Sync SHALL set the generated `inclusion` field to `manual`.
6. IF the Kiro_Sync cannot derive a `description` value from the source per Requirement 1.5, THEN THE Kiro_Sync SHALL set the `description` field to an empty string and complete generation of the Steering_Doc without aborting.

### Requirement 6: Check mode support and idempotency

**User Story:** As a developer relying on the pre-commit hook and CI, I want the Kiro target to support `--check` and be idempotent, so that un-synced Kiro output is detected and repeated syncs produce no changes.

#### Acceptance Criteria

1. WHILE the Sync_Script is running in Check_Mode, IF a generated Kiro file is missing OR its on-disk content differs byte-for-byte from the content the Sync_Script would produce in write mode, THEN THE Kiro_Sync SHALL report that specific file as out of sync in its output, identifying the file by path.
2. WHILE running in Check_Mode, THE Kiro_Sync SHALL leave the `.kiro/` tree and all other filesystem contents unmodified, creating, updating, or deleting no files.
3. IF at least one generated Kiro file is missing or differs during Check_Mode, THEN THE Sync_Script SHALL terminate with a non-zero exit status indicating drift.
4. WHEN a Check_Mode run completes in which every generated Kiro file is present and byte-for-byte identical to its expected content, THE Sync_Script SHALL terminate with a zero exit status indicating no drift.
5. WHEN the Sync_Script is run in write mode twice in succession with no changes to source inputs between runs, THE Kiro_Sync SHALL produce a `.kiro/` tree on the second run that is byte-for-byte identical to the tree after the first run, containing the same set of files with no additions, deletions, or modifications.
6. WHEN the Sync_Script is run in Check_Mode immediately after a successful write-mode run with no intervening source changes, THE Kiro_Sync SHALL report no drift and THE Sync_Script SHALL terminate with a zero exit status.

### Requirement 7: Regression isolation of existing host targets

**User Story:** As a Buildwright maintainer, I want the existing host targets to be unaffected by the Kiro addition, so that the change is safe to merge upstream.

#### Acceptance Criteria

1. WHEN the Sync_Script is executed with the Kiro_Sync target present, THE Sync_Script SHALL produce output for each Existing_Target (Claude Code, Codex, Cursor, and OpenCode) that is byte-identical to the output produced by the same Sync_Script run when the Kiro_Sync target is absent.
2. THE Kiro_Sync SHALL be defined as a section positioned after the existing Codex target section within the Sync_Script.
3. THE Sync_Script SHALL retain each existing target function definition byte-identical to its definition prior to the Kiro_Sync addition.
4. WHERE the Capability_Table is edited to add a Kiro column, THE existing capability rows SHALL retain their Claude Code, Codex, Cursor, OpenCode, and Fallback values byte-identical to their values prior to the Kiro column addition.
5. IF the Sync_Script encounters an error while processing the Kiro_Sync target, THEN THE Sync_Script SHALL leave each Existing_Target output byte-identical to its pre-change output and SHALL report failure via a non-zero exit status.

### Requirement 8: Add a Kiro column to the capability table

**User Story:** As a Buildwright user, I want the capability table to document Kiro's native primitives and fallbacks, so that commands stay tool-agnostic while resolving to Kiro capabilities.

#### Acceptance Criteria

1. WHEN the Capability_Table is updated, THE Capability_Table SHALL include exactly one Kiro column positioned immediately after the OpenCode column and immediately before the Fallback column, with no other column inserted between them.
2. THE Capability_Table SHALL populate the Kiro column with a non-empty native mapping value for every capability row present in the table, such that no Kiro cell is blank, null, or a placeholder dash.
3. WHERE Kiro lacks a native slash-command primitive, THE Capability_Table SHALL document in the Kiro cell of the command-invocation row that faithful command invocation degrades to loading the command text as a manually-included Steering_Doc referenced via the literal token `#bw-command-<name>`.
4. THE `.buildwright/framework/capability.md` document SHALL contain a note stating that the Kiro command-invocation fallback loads and preserves the real Buildwright command prose rather than substituting Kiro's own interpretation.
5. IF a capability row is added to or removed from the Capability_Table, THEN THE Capability_Table SHALL retain a non-empty Kiro column value for every remaining row so that the Kiro column stays in one-to-one correspondence with the capability rows.

### Requirement 9: Gitignore generated output and update project documentation

**User Story:** As a developer, I want generated Kiro output gitignored and the project structure docs updated, so that generated files are never committed and contributors understand the Kiro target.

#### Acceptance Criteria

1. WHEN a file matching `.kiro/steering/bw-*.md` or `.kiro/hooks/bw-*.kiro.hook` exists in the working tree, THE `.gitignore` file SHALL cause that file to report no change under `git status`.
2. WHERE the `.gitignore` entries are scoped to the BW_Namespace `bw-` prefix, THE committed Project_Steering_Docs that do not match the `bw-` prefix SHALL remain tracked by git.
3. IF a file under `.kiro/steering/` or `.kiro/hooks/` does not match the `bw-` prefix, THEN THE `.gitignore` entries SHALL NOT cause that file to be ignored.
4. WHEN the Kiro target is added, THE `AGENTS.md` Project Structure section SHALL list `.kiro/` as generated, gitignored output produced by the sync.
5. WHEN the Kiro target is added, THE `sync-agents.sh` header comment SHALL list each generated Kiro output path alongside the existing host outputs.

### Requirement 10: No new runtime dependencies

**User Story:** As a Buildwright maintainer, I want the Kiro target to reuse existing tooling, so that the change adds no new dependencies to the sync script.

#### Acceptance Criteria

1. THE Kiro_Sync SHALL invoke only external commands drawn from the set already required by the Sync_Script (`bash`, `find`, `sed`, `awk`, `mktemp`, `diff`, and the existing file-copy utilities), such that the set of external commands it invokes is a subset of the Sync_Script's existing command set.
2. WHEN the Kiro_Sync runs to completion, THE Kiro_Sync SHALL cause zero additions to the Sync_Script's declared dependency list (no new tool, package, or runtime added to any dependency manifest or documented prerequisite).
3. WHEN the Kiro_Sync performs an in-place text edit, THE Kiro_Sync SHALL perform that edit through the existing platform-aware `sed_inplace` helper and SHALL invoke no other in-place editing command.
4. IF the Kiro_Sync encounters a scenario that would require a command outside the Sync_Script's existing command set, THEN THE Kiro_Sync SHALL terminate with a non-zero exit status and emit an error message identifying the missing command, without modifying any target files.
