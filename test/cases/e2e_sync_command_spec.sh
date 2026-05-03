#!/usr/bin/env bash

source "$APPROVALS_BASH"

for f in "$LIB_PATH"/*.sh; do source "$f"; done

SRC_PATH="$PWD/../src"

describe "sync_command"

  TEMP_FILE_REGEX="\/var\/folders\/[^[:space:]]+"

  _make_sync_file() {
    local file_path="$1"
    local body="$2"
    shift 2
    {
      echo "---"
      for field in "$@"; do echo "$field"; done
      echo "---"
      echo
      printf '%s\n' "$body"
    } > "$file_path"
  }

  context "noop - no changes"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Noop Note" \
      "apple_notes_id: x-coredata://noop/ICNote/p1" \
      "stash_last_synced_at: 2020-01-01T00:00:00Z" \
      "stash_last_local_hash: SAMEHASH" \
      "stash_last_remote_hash: SAMEHASH"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      compute_content_hash() { echo 'SAMEHASH'; }
      find_note() { echo 'x-coredata://noop/ICNote/p1'; return 0; }
      read_note() { echo '<p>Noop Note</p>'; return 0; }
      get_note_folder_path() { echo 'NoopFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'
      source \$SRC_PATH/sync_command.sh
      unset -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
    " "sync_noop"

    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    approve "cat $file_path" "sync_noop_file"
    rm -f "$file_path"

  context "push - local changed, remote unchanged"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Push Note - Changed" \
      "apple_notes_id: x-coredata://push/ICNote/p2" \
      "stash_last_synced_at: 2020-01-01T00:00:00Z" \
      "stash_last_local_hash: OLDHASH" \
      "stash_last_remote_hash: OLDHASH"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      compute_content_hash() {
        case \"\$1\" in
          *Push*) echo 'NEWHASH' ;;
          *) echo 'OLDHASH' ;;
        esac
      }
      find_note() { echo 'x-coredata://push/ICNote/p2'; return 0; }
      read_note() { echo '<h1>Push Note</h1><p>Original remote content.</p>'; return 0; }
      update_note() { return 0; }
      get_note_folder_path() { echo 'PushFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f compute_content_hash find_note read_note update_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'
      source \$SRC_PATH/sync_command.sh
      unset -f compute_content_hash find_note read_note update_note get_note_folder_path acquire_lock release_lock
    " "sync_push"

    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    approve "cat $file_path" "sync_push_file"
    rm -f "$file_path"

  context "pull - remote changed, local unchanged"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Pull Note" \
      "apple_notes_id: x-coredata://pull/ICNote/p3" \
      "stash_last_synced_at: 2020-01-01T00:00:00Z" \
      "stash_last_local_hash: OLDHASH" \
      "stash_last_remote_hash: OLDHASH"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      compute_content_hash() {
        case \"\$1\" in
          *Remote\ content\ that\ changed*) echo 'NEWHASH' ;;
          *) echo 'OLDHASH' ;;
        esac
      }
      find_note() { echo 'x-coredata://pull/ICNote/p3'; return 0; }
      read_note() { echo '<p>Remote content that changed.</p>'; return 0; }
      get_note_folder_path() { echo 'PullFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'
      source \$SRC_PATH/sync_command.sh
      unset -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
    " "sync_pull"

    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    approve "cat $file_path" "sync_pull_file"
    rm -f "$file_path"

  context "conflict - both changed differently"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Conflict Note - Local Change" \
      "apple_notes_id: x-coredata://conflict/ICNote/p4" \
      "stash_last_synced_at: 2020-01-01T00:00:00Z" \
      "stash_last_local_hash: OLDHASH" \
      "stash_last_remote_hash: OLDHASH"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      compute_content_hash() {
        case \"\$1\" in
          *Local\ Change*) echo 'LOCAL_CHANGE' ;;
          *Remote\ change*) echo 'REMOTE_CHANGE' ;;
          *) echo 'OLDHASH' ;;
        esac
      }
      find_note() { echo 'x-coredata://conflict/ICNote/p4'; return 0; }
      read_note() { echo '<p>Remote change.</p>'; return 0; }
      get_note_folder_path() { echo 'ConflictFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'
      source \$SRC_PATH/sync_command.sh
      unset -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
    " "sync_conflict"

    allow_diff "\/var\/folders\/[^[:space:]]+"
    approve "cat ${file_path%.md}.conflict.md" "sync_conflict_file"
    rm -f "$file_path" "${file_path%.md}.conflict.md"

  context "bootstrap_metadata - first sync, no prior metadata"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Bootstrap Note" \
      "apple_notes_id: x-coredata://bootstrap/ICNote/p5"

    allow_diff "$TEMP_FILE_REGEX"
    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    allow_diff "stash_last_local_hash: [a-f0-9]+"
    allow_diff "stash_last_remote_hash: [a-f0-9]+"
    approve "
      find_note() { echo 'x-coredata://bootstrap/ICNote/p5'; return 0; }
      read_note() { echo '<p>Remote content.</p>'; return 0; }
      get_note_folder_path() { echo 'BootstrapFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f find_note read_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'
      source \$SRC_PATH/sync_command.sh
      unset -f find_note read_note get_note_folder_path acquire_lock release_lock
    " "sync_bootstrap"

    approve "cat $file_path" "sync_bootstrap_file"
    rm -f "$file_path"

  context "create_note - no apple_notes_id, note not found"
    file_path=$(mktemp)
    echo "# New Note" > "$file_path"

    allow_diff "$TEMP_FILE_REGEX"
    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    allow_diff "stash_last_local_hash: [a-f0-9]+"
    allow_diff "stash_last_remote_hash: [a-f0-9]+"
    approve "
      find_note() { return 1; }
      create_note() { echo 'x-coredata://new/ICNote/p6'; return 0; }
      get_note_folder_path() { echo 'NewFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f find_note create_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'; args[yes]='1'
      source \$SRC_PATH/sync_command.sh
      unset -f find_note create_note get_note_folder_path acquire_lock release_lock
    " "sync_create_note"

    approve "cat $file_path" "sync_create_note_file"
    rm -f "$file_path"

  context "missing_ignore - note deleted, ignore policy"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Missing Note" \
      "apple_notes_id: x-coredata://missing/ICNote/p7"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { return 1; }
      get_note_folder_path() { return 1; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f find_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'; args[yes]='1'; args[deletion_policy]='ignore'
      source \$SRC_PATH/sync_command.sh
      unset -f find_note get_note_folder_path acquire_lock release_lock
    " "sync_missing_ignore"
    rm -f "$file_path"

  context "missing_archive - note deleted, archive policy"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Archive Me" \
      "apple_notes_id: x-coredata://archive/ICNote/p8"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      find_note() { return 1; }
      get_note_folder_path() { return 1; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f find_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'; args[yes]='1'; args[deletion_policy]='archive'
      source \$SRC_PATH/sync_command.sh
      unset -f find_note get_note_folder_path acquire_lock release_lock
    " "sync_missing_archive"
    rm -f "$file_path"

  context "missing_propagate - note deleted, propagate creates new"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Propagate Me" \
      "apple_notes_id: x-coredata://propagate/ICNote/p9"

    allow_diff "$TEMP_FILE_REGEX"
    allow_diff "stash_last_synced_at: [0-9TZ:\-]+"
    allow_diff "stash_last_local_hash: [a-f0-9]+"
    allow_diff "stash_last_remote_hash: [a-f0-9]+"
    approve "
      find_note() { return 1; }
      create_note() { echo 'x-coredata://propagate/ICNote/p10'; return 0; }
      get_note_folder_path() { echo 'PropagateFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f find_note create_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'; args[yes]='1'; args[deletion_policy]='propagate'
      source \$SRC_PATH/sync_command.sh
      unset -f find_note create_note get_note_folder_path acquire_lock release_lock
    " "sync_missing_propagate"

    approve "cat $file_path" "sync_missing_propagate_file"
    rm -f "$file_path"

  context "dry_run - no changes written"
    file_path=$(mktemp)
    _make_sync_file "$file_path" "# Dry Run Note" \
      "apple_notes_id: x-coredata://dryrun/ICNote/p11" \
      "stash_last_synced_at: 2020-01-01T00:00:00Z" \
      "stash_last_local_hash: OLDHASH" \
      "stash_last_remote_hash: OLDHASH"

    allow_diff "$TEMP_FILE_REGEX"
    approve "
      compute_content_hash() {
        case \"\$1\" in
          *Changed\ remote*) echo 'NEWHASH' ;;
          *) echo 'OLDHASH' ;;
        esac
      }
      find_note() { echo 'x-coredata://dryrun/ICNote/p11'; return 0; }
      read_note() { echo '<p>Changed remote.</p>'; return 0; }
      get_note_folder_path() { echo 'DryRunFolder'; return 0; }
      acquire_lock() { echo '/dev/null'; return 0; }
      release_lock() { return 0; }
      export -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
      declare -A args; args[file]='$file_path'; args[dry_run]='1'
      source \$SRC_PATH/sync_command.sh
      unset -f compute_content_hash find_note read_note get_note_folder_path acquire_lock release_lock
    " "sync_dry_run"

    approve "cat $file_path" "sync_dry_run_file"
    rm -f "$file_path"
