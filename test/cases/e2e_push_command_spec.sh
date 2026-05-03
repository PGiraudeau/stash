#!/usr/bin/env bash

source "$APPROVALS_BASH"

# Source all lib functions
for f in "$LIB_PATH"/*.sh; do source "$f"; done

SRC_PATH="$PWD/../src"

describe "push_command"

  # Regex to normalize temp file paths in output
  TEMP_FILE_REGEX="\/var\/folders\/[^[:space:]]+"

  # Test 1: New file, user confirms -> creates note, adds frontmatter
  context "new file, user confirms"
    test_file=$(mktemp)
    echo "# Test Note" > "$test_file"
    
    # Create inline script with mocks
    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { return 1; }
      create_note() { echo 'x-coredata://test/ICNote/p123'; return 0; }
      get_note_folder_path() { echo 'TestFolder'; return 0; }
      export -f find_note create_note get_note_folder_path
      declare -A args; args[file]='$test_file'
      echo 'y' | source $SRC_PATH/push_command.sh
      unset -f find_note create_note get_note_folder_path
    " "push_new_file_confirm"
    
    # Verify frontmatter was updated
    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    approve "cat $test_file" "push_new_file_confirm_frontmatter"
    
    rm -f "$test_file"

  # Test 2: New file, user cancels -> exits cleanly
  context "new file, user cancels"
    test_file=$(mktemp)
    echo "# Test Note" > "$test_file"
    
    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { return 1; }
      export -f find_note
      declare -A args; args[file]='$test_file'
      echo 'n' | source $SRC_PATH/push_command.sh
      unset -f find_note
    " "push_new_file_cancel"
    
    rm -f "$test_file"

  # Test 3: Existing file with valid ID -> updates note
  context "existing note"
    test_file=$(mktemp)
    cat > "$test_file" << 'EOF'
---
apple_notes_id: x-coredata://existing/ICNote/p456
---
# Existing Note
EOF
    
    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { echo 'x-coredata://existing/ICNote/p456'; return 0; }
      update_note() { echo \"\$1\"; return 0; }
      get_note_folder_path() { echo 'ExistingFolder'; return 0; }
      export -f find_note update_note get_note_folder_path
      declare -A args; args[file]='$test_file'
      source $SRC_PATH/push_command.sh
      unset -f find_note update_note get_note_folder_path
    " "push_existing_note"
    
    rm -f "$test_file"

  # Test 4: Orphaned ID, user confirms -> creates new note, updates frontmatter
  context "orphaned ID, user confirms"
    test_file=$(mktemp)
    cat > "$test_file" << 'EOF'
---
apple_notes_id: x-coredata://orphaned/ICNote/p789
---
# Orphaned Note
EOF
    
    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { return 1; }
      create_note() { echo 'x-coredata://new/ICNote/p999'; return 0; }
      get_note_folder_path() { echo 'OrphanedFolder'; return 0; }
      export -f find_note create_note get_note_folder_path
      declare -A args; args[file]='$test_file'
      echo 'y' | source $SRC_PATH/push_command.sh
      unset -f find_note create_note get_note_folder_path
    " "push_orphaned_id_confirm"
    
    # Verify frontmatter was updated with new ID
    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    approve "cat $test_file" "push_orphaned_id_confirm_frontmatter"
    
    rm -f "$test_file"

  # Test 5: Orphaned ID, user cancels -> exits cleanly
  context "orphaned ID, user cancels"
    test_file=$(mktemp)
    cat > "$test_file" << 'EOF'
---
apple_notes_id: x-coredata://orphaned/ICNote/p789
---
# Orphaned Note
EOF
    
    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { return 1; }
      export -f find_note
      declare -A args; args[file]='$test_file'
      echo 'n' | source $SRC_PATH/push_command.sh
      unset -f find_note
    " "push_orphaned_id_cancel"
    
    rm -f "$test_file"

  # Test 6: Non-existent file -> error
  context "non-existent file"
    approve "
      declare -A args; args[file]='/nonexistent/path/to/file.md'
      source $SRC_PATH/push_command.sh 2>&1 || true
    " "push_nonexistent_file"
