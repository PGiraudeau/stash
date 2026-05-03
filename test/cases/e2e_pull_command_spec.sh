#!/usr/bin/env bash

source "$APPROVALS_BASH"

# Source all lib functions
for f in "$LIB_PATH"/*.sh; do source "$f"; done

SRC_PATH="$PWD/../src"

describe "pull_command"

  # Regex to normalize temp file paths in output
  TEMP_FILE_REGEX="\/var\/folders\/[^[:space:]]+"

  # Test 1: Existing note -> pulls content and updates file
  context "existing note"
    test_file=$(mktemp)
    cat > "$test_file" << 'EOF'
---
apple_notes_id: x-coredata://test/ICNote/p123
---
# Original Content
EOF

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { echo 'x-coredata://test/ICNote/p123'; return 0; }
      read_note() { echo '<p>Pulled content from Apple Notes</p>'; return 0; }
      get_note_folder_path() { echo 'TestFolder'; return 0; }
      export -f find_note read_note get_note_folder_path
      declare -A args; args[file]='$test_file'
      source \$SRC_PATH/pull_command.sh
      unset -f find_note read_note get_note_folder_path
    " "pull_existing_note"

    # Verify file content (frontmatter + empty line + pulled content)
    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    approve "cat $test_file" "pull_existing_note_content"

    rm -f "$test_file"

  # Test 2: File without apple_notes_id -> error
  context "no frontmatter"
    test_file=$(mktemp)
    echo "# No Frontmatter" > "$test_file"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      declare -A args; args[file]='$test_file'
      source \$SRC_PATH/pull_command.sh 2>&1 || true
      unset args
    " "pull_no_frontmatter"

    rm -f "$test_file"

  # Test 3: Note not found in Apple Notes -> error
  context "note not found"
    test_file=$(mktemp)
    cat > "$test_file" << 'EOF'
---
apple_notes_id: x-coredata://orphaned/ICNote/p999
---
# Orphaned Note
EOF

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { return 1; }
      export -f find_note
      declare -A args; args[file]='$test_file'
      source \$SRC_PATH/pull_command.sh 2>&1 || true
      unset -f find_note
    " "pull_note_not_found"

    rm -f "$test_file"

  # Test 4: Non-existent file -> error
  context "non-existent file"
    approve "
      declare -A args; args[file]='/nonexistent/path/to/file.md'
      source \$SRC_PATH/pull_command.sh 2>&1 || true
    " "pull_nonexistent_file"
