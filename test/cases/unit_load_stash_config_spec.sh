#!/usr/bin/env bash

source "$APPROVALS_BASH"
source "$LIB_PATH/load_stash_config.sh"

describe "load_stash_config"

  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/repo/sub"
  cat > "$tmp_dir/repo/.stash.yml" <<'EOF'
apple:
  base_folder: Projects:Personal
sync:
  dry_run_default: true
EOF

  allow_diff "\/var\/folders\/[^[:space:]]+"
  approve "load_stash_config '$tmp_dir/repo/sub/file.md'" "load_stash_config_path_discovery"
  approve "get_config_value '$tmp_dir/repo/.stash.yml' 'apple.base_folder'" "load_stash_config_base_folder"
  approve "get_config_value '$tmp_dir/repo/.stash.yml' 'sync.dry_run_default'" "load_stash_config_dry_run"

  rm -rf "$tmp_dir"
