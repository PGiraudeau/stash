#!/usr/bin/env bash

source "$APPROVALS_BASH"

source "$LIB_PATH/prepare_links_for_push.sh"
source "$LIB_PATH/restore_links_from_pull.sh"

describe "link roundtrip"

  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/sub"
  source_file="$tmp_dir/sub/note.md"
  touch "$source_file"

  index_data=$'sub/target.md|x-coredata://TARGET/ICNote/p42\n'

  content='See [Target](target.md) and [Outside](../other.md#x) and [Web](https://example.com).'
  approve "echo '$content' | prepare_links_for_push '$source_file' '$tmp_dir' \"$index_data\"" "prepare_links_for_push_with_index"

  pushed='See [Target](stash-md://sub/target.md?note_id=x-coredata://TARGET/ICNote/p42) and [Outside](stash-md://other.md#x) and [Web](https://example.com).'
  approve "echo '$pushed' | restore_links_from_pull '$source_file' '$tmp_dir'" "restore_links_from_pull_with_note_id"

  rm -rf "$tmp_dir"
