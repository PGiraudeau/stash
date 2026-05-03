#!/usr/bin/env bash

source "$APPROVALS_BASH"

source "$LIB_PATH/prepare_links_for_push.sh"
source "$LIB_PATH/restore_links_from_pull.sh"

describe "asset link roundtrip"

  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/sub" "$tmp_dir/assets"
  source_file="$tmp_dir/sub/note.md"
  touch "$source_file"

  content='See [Image](../assets/logo.png) and [Doc](target.md).'
  approve "echo '$content' | prepare_links_for_push '$source_file' '$tmp_dir' ''" "prepare_links_for_push_with_assets"

  pushed='See [Image](stash-asset://assets/logo.png) and [Doc](stash-md://sub/target.md).'
  approve "echo '$pushed' | restore_links_from_pull '$source_file' '$tmp_dir'" "restore_links_from_pull_with_assets"

  rm -rf "$tmp_dir"
