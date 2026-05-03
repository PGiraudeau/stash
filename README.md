```
                                     
                                     
  ▄█████ ██████ ▄████▄ ▄█████ ██  ██ 
  ▀▀▀▄▄▄   ██   ██▄▄██ ▀▀▀▄▄▄ ██████ 
  █████▀   ██   ██  ██ █████▀ ██  ██ 
                                     
                                     
```

Bidirectionally sync Markdown files with Apple Notes!

## Getting Started

### Installation

```bash
> Fork
brew tap PGiraudeau/stash https://github.com/PGiraudeau/stash
brew install PGiraudeau/stash/stash

> Original Creator and Branch
brew tap shakedlokits/stash https://github.com/shakedlokits/stash
brew install shakedlokits/stash/stash
```

Pre-merge branch testing (recommended):

```bash
git clone --branch feature/future-implementation https://github.com/PGiraudeau/stash.git
cd stash
docker run --rm --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly generate
./dist/stash --version
```

Apple Silicon note:

```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zprofile
source ~/.zprofile
```

### Quick Example

Push a markdown file to Apple Notes:
```bash
stash push my-note.md
```

Push a whole folder recursively:
```bash
stash push notes/
```

Push to a target Apple Notes base folder:
```bash
stash push notes/ --folder "Projects:Personal"
```

Pull changes back from Apple Notes:
```bash
stash pull my-note.md
```

Two-way sync (Git-first with conflict-safe behavior):
```bash
stash sync notes/ --folder "Projects:Personal"
```

Preview actions only:
```bash
stash sync notes/ --dry-run
```

Emit machine-readable actions:
```bash
stash sync notes/ --json
```

Missing-note policy:
```bash
stash sync notes/ --deletion-policy ignore
stash sync notes/ --deletion-policy archive
stash sync notes/ --deletion-policy propagate
```

Mirror local directory paths into Apple Notes on push updates:
```bash
stash sync notes/ --folder "Projects:Personal" --mirror-path
```

Materialize missing local files from Apple Notes before syncing (folder mode):
```bash
stash sync notes/ --folder "Projects:Personal" --materialize-remote
```

Pull a whole folder recursively:
```bash
stash pull notes/
```

That's it! The tool uses front-matter to track which Apple Note corresponds to your file.

## Background & Rationale

Apple Notes has been my daily driver for years. I love its simplicity—it syncs fast, stays out of the way, and just lets me write.

I've explored the full spectrum of note-taking apps: `Workflowy`, `Obsidian`, `Bear`, `Evernote`, `Notion`, `Google Keep`, `GoodNotes`, and others I've since forgotten. Each promised to revolutionize how I capture thoughts. But eventually, I realized something simple: note-taking is about writing things down, not managing a complex system. I came back to Apple Notes and haven't looked back.

There's just one friction point. When I'm building things—which is most days—I live in Markdown. At work, I sync those files to Notion or Confluence with CLI tools. For personal projects, everything goes into Git. But increasingly, I find myself writing quick notes that don't belong to any project—just ideas, experiments, small discoveries—and I want them on Apple Notes where I can read them anywhere. Right now, there's no clean path from my Markdown workflow to my notes.

I went searching for CLI tools to bridge this gap. What I found was disappointing: tools either pack in too many features, making them brittle and hard to maintain, or they offer so little functionality (read-only sync) that they're effectively useless.

So I built my own.

The requirements are straightforward:
- Run from the shell without configuration files
- Use AppleScript for maximum compatibility and stability
- Bidirectionally sync Markdown and Apple Notes, using front-matter to track state

## How It Works

### Pushing Notes

Congratulations! You've written a new Markdown note, it's nice and tidy, and you've even run `vale` on it. Now all that remains is getting it into Apple Notes. Here's what you need to do:

1. Run `push my-cool-note.md`.
2. A new note will be created:
   ```
   My Cool Note
   ...
   ```
3. Front-matter with a unique identifier and sync metadata will be added to your markdown file:
   ```md
   ---
   apple_notes_id: x-coredata://...
   stash_last_synced_at: 2026-01-01T00:00:00Z
   stash_last_local_hash: abc123...
   stash_last_remote_hash: abc123...
   stash_note_path: Projects:Personal
   ---

   # My Cool Note
   ...
   ```
   > NOTE: If you already have front-matter, it will be preserved and updated in place.

Made changes to the Markdown file and now it's out of sync? Simply:
1. Rerun `push my-cool-note.md`.
2. The tool searches for the note matching your identifier.
3. It rewrites the note's content with your updated Markdown and updates the sync hashes.
   > NOTE: If no note was found (due to unexpected ID changes) you will be asked if you'd like to create a new note, which will overwrite your previous ID.

### Pulling Notes

You've gone off for your coffee/potty/meeting break, and while skimming through your note on your phone, you realized you made a terrible mistake—which inevitably led you to rewrite half of it.

Now the panic has settled, you're back at your computer, and you're wondering: "What the hell have I done, and how can I possibly get all those changes back into my Markdown?"

Don't fret. Simply:
1. Run `pull my-cool-note.md`.
2. The tool searches for the note matching your identifier.
3. It rewrites your local Markdown file with the content from Apple Notes and updates the sync metadata.

## Requirements

- **macOS** with Apple Notes
- **Bash 5+**
- **[Pandoc](https://pandoc.org/installing.html)** for Markdown ↔ HTML conversion

## Folder Sync and Local Links

- `push` and `pull` accept either a file or a directory.
- Directory sync is recursive for all `*.md` files.
- When pushing directories, missing Apple Notes folder paths are created automatically.
- Use `--folder "A:B:C"` to set a base Apple Notes folder.
- Local Markdown links to other `.md` files are preserved across push/pull roundtrips.
- Relative asset links (for example images/files) are preserved across push/sync/pull roundtrips.

Canonical roundtrip forms used internally:

- Note links: `stash-md://...` (with optional `?note_id=...`)
- Asset links: `stash-asset://...`

These forms are used during sync conversion to keep link intent stable across directions.

## Sync metadata

`push`, `pull`, and `sync` all maintain metadata in frontmatter for deterministic change detection:

- `stash_last_synced_at`
- `stash_last_local_hash`
- `stash_last_remote_hash`
- `stash_note_path`

This ensures consistent behavior regardless of which command you use — `sync` won't
see false conflicts after a standalone `push` or `pull`.

## Optional repository config

You can define defaults in `.stash.yml`:

```yaml
apple:
  base_folder: Projects:Personal
sync:
  dry_run_default: false
```

CLI flags override config values.

## Implementation status (feature/future-implementation)

Implemented:

- `sync` command for two-way workflows (`--dry-run`, `--yes`, `--folder`).
- Deterministic sync metadata in frontmatter:
  - `stash_last_synced_at`
  - `stash_last_local_hash`
  - `stash_last_remote_hash`
  - `stash_note_path`
- Conflict-safe behavior via `<file>.conflict.md` outputs.
- Link index based local Markdown link preservation across push/sync/pull.
- Optional `.stash.yml` defaults for:
  - `apple.base_folder`
  - `sync.dry_run_default`
- JSON action output via `--json`.
- Sync locking and action logging under `.stash/`.
- Missing-note policies via `--deletion-policy` (`ignore|archive|propagate`).
- Optional path mirroring via `--mirror-path`.
- Optional remote tree materialization via `--materialize-remote` (create missing local files from Notes before sync).
- Canonical link persistence on pull for note links (`stash-md://...`) with `note_id` hints retained.
- Asset link roundtrip support via `stash-asset://...` internal form.
- Safer remote materialization filename handling (collision suffixing).

Validation done during implementation:

- Shell syntax checks (`bash -n`) for `src/*.sh` and `src/lib/*.sh`.
- Unit specs added for new helper modules and link/config logic.

Note:

- Full `test/approve` execution requires runtime dependencies (notably `pandoc`) available on the host.

## Apple Silicon (M1/M2/M3/M4) Quick Start

```bash
brew install bash pandoc
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zprofile
source ~/.zprofile
stash --version
```

On first use, macOS will ask permission to control Notes via Automation (osascript). Approve it, or sync commands will fail.

Optional local smoke check:

```bash
make smoke-local
```

## Design

The tool is built in three layers:

**AppleScript** forms the core, handling all communication with Apple Notes—finding existing notes, updating content, and creating or deleting notes (the latter mostly for testing).

**Shell scripts** contain the business logic that orchestrates these AppleScript operations, managing the sync workflow and front-matter processing.

**[Pandoc](https://pandoc.org)** handles the conversion between Markdown and HTML, ensuring content is properly formatted for Apple Notes.

**[`Bashly`](https://bashly.dev)** ties it all together, providing a clean CLI interface, shell completions, and command scaffolding.

## Development

### Setup

Clone the repository and build:

```bash
git clone https://github.com/shakedlokits/stash.git
cd stash
make build
```

### Running Tests

```bash
# Run all tests (requires Apple Notes access)
make test

# Run unit tests only (no Apple Notes required)
make test-unit
```

### Project Structure

```
src/
  lib/           # Utility functions (pure and integration)
  bashly.yml     # CLI configuration
  *_command.sh   # Command implementations
test/
  cases/         # Test specs (unit, integration, e2e)
  fixtures/      # Test fixture files
  approvals/     # Approval test snapshots
dist/
  stash          # Generated CLI (via bashly)
Formula/
  stash.rb       # Homebrew formula
```

### Creating a Release

```bash
make release VERSION=x.y.z
```

This will:
1. Update the version in `src/bashly.yml`
2. Commit the change
3. Create and push a git tag
4. Trigger the release workflow (build, publish, update Homebrew formula)

---

## Attribution

Original code and project concept by **Shaked Lokits**: <https://github.com/shakedlokits/stash>
This repository is a maintained fork.
