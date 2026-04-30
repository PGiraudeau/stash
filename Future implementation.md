# Implementation roadmap and status

## Goal

Evolve `stash` from push/pull helpers into a robust **Git-first bi-directional sync engine**:

- Git repo remains the source of truth.
- Apple Notes edits are still captured and synchronized back safely.
- Links between notes remain stable and usable in both Markdown and Apple Notes.

This plan is based on the current codebase (`push`, `pull`, `diff`, frontmatter `apple_notes_id`, folder recursion, and `--folder` support).

---

## Current baseline (already implemented)

- File and directory recursive sync (`push`, `pull` on `*.md`).
- Note identity via frontmatter `apple_notes_id`.
- Folder mapping (`--folder`, colon-separated Apple folder path).
- Auto-create Apple folders when creating notes.
- Basic local-link roundtrip wrapper (`stash-md://...` conversion).
- `diff` command for file-level comparison.

---

## Target feature set

## 1) Add a first-class `sync` command (2-way)

### Why
Current model requires manual choice between `push` and `pull`. A Git-first workflow needs one deterministic command for daily use.

### Behavior
`stash sync <path> [--folder ...] [--dry-run] [--yes]`

Per file:
1. Read local markdown.
2. Resolve note by `apple_notes_id`.
3. Compare local vs remote vs last-synced metadata.
4. Decide action:
   - push local,
   - pull remote,
   - create note,
   - create file,
   - conflict.

### Output
Structured per-file action summary with final totals.

---

## 2) Add sync metadata in frontmatter

### Why
Need deterministic conflict detection, not heuristic based on content only.

### Proposed fields
```yaml
apple_notes_id: x-coredata://...
stash_last_synced_at: 2026-04-29T20:00:00Z
stash_last_local_hash: <sha256>
stash_last_remote_hash: <sha256>
stash_note_path: Projects:Personal:subfolder
```

### Rules
- `apple_notes_id` remains mandatory identity key.
- Hashes represent normalized markdown body (frontmatter excluded).
- Metadata updates only after successful sync action.

---

## 3) Conflict-safe sync model

### Why
If edits happened both in Git and Apple Notes, blind overwrite loses data.

### Decision matrix (core)
- Only local changed since last sync → push.
- Only remote changed since last sync → pull.
- Neither changed → no-op.
- Both changed and resulting bodies differ → conflict.

### Conflict handling
Create sibling file:
- `<name>.conflict.md`

Include:
- frontmatter preserved,
- local body,
- pulled remote body,
- decision hints.

No destructive overwrite in conflict mode.

---

## 4) Improve link preservation (real link graph)

### Why
Current `stash-md://` wrapper is useful but not enough for robust cross-note navigation.

### Proposed model
Build an index for the sync scope:
- local path
- note id
- canonical relative path
- resolved Apple note deep link (when available)

### Push link transform
For local links like:
- `./foo.md`
- `../bar/baz.md#anchor`

Resolve target file, then:
- if target has note id, convert to Apple-deeplink-compatible form (or keep stash-md if deeplink not reliable),
- preserve fragment anchors.

### Pull link transform
Convert back to relative markdown links according to local file location.

Status update:
- Note links now preserve canonical `stash-md://...` form on pull (including `note_id` hints).
- Asset links now roundtrip through canonical `stash-asset://...` form.

### Safety
If target note/file missing, keep original markdown link unchanged and warn.

---

## 5) Add optional repo config file

### Why
Avoid repeating flags and make team usage reproducible.

### File
`.stash.yml` at repo root.

### Suggested schema
```yaml
version: 1
roots:
  - notes/
apple:
  base_folder: Projects:Personal
sync:
  mode: git-first
  conflict: file
  dry_run_default: false
  deletion_policy: archive
filters:
  include: ["**/*.md"]
  exclude: ["**/.obsidian/**", "**/node_modules/**"]
links:
  strategy: preserve-and-resolve
```

### Precedence
CLI args > `.stash.yml` > defaults.

---

## 6) Rename/move detection

### Why
In Git workflows, files move often. We should keep note identity stable and avoid duplicate note creation.

### Approach
- If file moved but still carries same `apple_notes_id`, update `stash_note_path` metadata.
- On push, optionally move note into new Apple folder path if `--mirror-path` is enabled.

Status update:
- `--mirror-path` implemented for optional note folder path mirroring.
- Remote folder path change detection now updates sync metadata even on no-op content sync.

---

## 7) Deletion policy

### Why
Bidirectional sync needs explicit behavior for deleted files/notes.

### Modes
- `ignore` (default initially): do nothing, report drift.
- `archive`: move note or file into archive location.
- `propagate`: mirror deletion (dangerous, requires `--yes`).

---

## 8) Dry-run and machine-readable output

### Why
Critical for CI/GitLab pipelines and safe previews.

### Add
- `--dry-run`: print planned actions only.
- `--json`: emit action records for automation.

Action record fields:
- file
- note_id
- action
- reason
- changed_hashes
- status

---

## 9) Reliability and locking

### Why
Concurrent runs can corrupt sync state.

### Add
- lock file `.stash/lock`
- operation logs `.stash/log.jsonl`
- transactional write flow:
  - write temp file
  - fsync/move replace

---

## 10) Test strategy expansion

Current tests are strong for single-file flows, but new behavior needs broader coverage.

### New unit tests
- hash generation normalization
- sync decision matrix
- link resolver/rewriter
- config merge precedence

### New e2e tests
- directory sync mixed states
- conflict file generation
- dry-run output stability
- base folder scope checks

### Integration tests (Apple Notes)
- folder path creation and nesting
- note path validation
- roundtrip links in realistic notes

Status update:
- Added targeted approval coverage for asset link roundtrip and canonical link handling.
- Full integration/e2e execution still requires macOS host tooling (`osascript`, build tooling) and approvals refresh in that environment.

---

## Implementation plan (phased)

## Phase 1: Sync core (high impact)
1. Add `sync_command.sh`.
2. Add metadata helpers:
   - `compute_content_hash.sh`
   - `read_sync_metadata.sh`
   - `update_sync_metadata.sh`
3. Add decision engine:
   - `resolve_sync_action.sh`
4. Add `--dry-run` support.

Deliverable: safe deterministic 2-way sync + conflict files.

Status: ✅ Implemented

## Phase 2: Link graph
1. Build note/file index helper.
2. Replace basic link wrappers with resolver-aware transforms.
3. Add fallback behavior and warnings.

Deliverable: resilient cross-note links in both worlds.

Status: ✅ Implemented (index-based link mapping with note ID hints)

## Phase 3: Config + automation
1. Add `.stash.yml` loader/validator.
2. Add `--json` output.
3. Add lock/log.

Deliverable: GitLab-friendly operational sync.

Status: ✅ Implemented (core subset: `.stash.yml` defaults, lock, log, `--json`)

## Phase 4: Deletions + path-mirroring
1. Add deletion policy engine.
2. Add optional note move mirroring.
3. Harden recovery and rollback behaviors.

Deliverable: complete lifecycle sync.

Status: ✅ Implemented (missing-note policies + optional path mirroring)

## Phase 5: P0 hardening for full-folder bi-directional workflows
1. Preserve canonical note links with `note_id` hints across pull/sync.
2. Materialize remote Notes subtree locally before sync when requested.
3. Add safer filename collision handling during remote materialization.
4. Add canonical asset link roundtrip handling.

Deliverable: robust folder-level workflows (GitLab/Notes) with stable links and reduced drift.

Status: ✅ Implemented (`--materialize-remote`, canonical `stash-md://` preservation, `stash-asset://` roundtrip, collision suffixing)

---

## Proposed CLI evolution

```bash
stash sync notes/ --folder "Projects:Personal"
stash sync notes/ --dry-run
stash sync notes/ --json
stash sync notes/ --deletion-policy archive
stash sync notes/ --materialize-remote
```

(Keep `push`, `pull`, `diff` for explicit/manual workflows.)

---

## Risks and mitigations

1. Apple Notes API quirks via AppleScript
- Mitigation: isolate AppleScript ops in lib wrappers and expand integration tests.

2. Link resolution edge cases
- Mitigation: strict parser + fallback to untouched original links.

3. Conflict fatigue in active notebooks
- Mitigation: clear conflict report and optional strategy tuning.

4. Metadata drift in manually edited frontmatter
- Mitigation: metadata validation + repair mode (`stash sync --repair`, future).

---

## Definition of done (for initial sync milestone)

- `stash sync` works on file and directory scopes.
- No silent overwrite on dual edits.
- Conflicts materialize as explicit files.
- Metadata hashes/time are maintained consistently.
- Dry-run accurately matches real execution plan.
- E2E + unit tests cover decision matrix and conflict flow.

---

## Notes on compatibility

- Keep existing frontmatter key `apple_notes_id` unchanged.
- Keep existing `push/pull/diff` behavior stable unless flags explicitly opt into new behavior.
- Keep Apple Silicon compatibility constraints (no extra fragile deps).
