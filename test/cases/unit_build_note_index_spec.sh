#!/usr/bin/env bash

source "$APPROVALS_BASH"

source "$LIB_PATH/read_markdown_file.sh"
source "$LIB_PATH/get_id_from_frontmatter.sh"
source "$LIB_PATH/build_note_index.sh"

describe "build_note_index"

  tmp_dir=$(mktemp -d)
  mkdir -p "$tmp_dir/sub"

  cat > "$tmp_dir/a.md" <<'EOF'
---
apple_notes_id: x-coredata://A/ICNote/p1
---
# A
EOF

  cat > "$tmp_dir/sub/b.md" <<'EOF'
---
apple_notes_id: x-coredata://B/ICNote/p2
---
# B
EOF

  echo "# no id" > "$tmp_dir/sub/c.md"

  allow_diff "\/var\/folders\/[^[:space:]]+"
  approve "build_note_index '$tmp_dir'" "build_note_index_basic"

  rm -rf "$tmp_dir"
