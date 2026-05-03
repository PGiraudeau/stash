#!/usr/bin/env bash

source "$APPROVALS_BASH"
source "$LIB_PATH/write_markdown_file.sh"

# Create a temporary directory for test files
TEST_TMP_DIR=$(mktemp -d)

describe "write_markdown_file"
  
  # Test 1: Write content to existing file
  test_file="$TEST_TMP_DIR/test_write.md"
  echo "Original content" > "$test_file"
  write_markdown_file "$test_file" "Updated content"
  approve "cat \"$test_file\"" "write_markdown_file_overwrite"
  
  # Test 2: Write empty content to existing file
  empty_file="$TEST_TMP_DIR/empty.md"
  echo "Some content" > "$empty_file"
  write_markdown_file "$empty_file" ""
  approve "cat \"$empty_file\" || echo \"Exit code: \$?\"" "write_markdown_file_empty"
  
  # Test 3: No file path provided (should fail)
  approve "write_markdown_file \"\" \"content\" || echo \"Exit code: \$?\"" "write_markdown_file_no_path"
  
  # Test 4: Create new file (should succeed)
  new_file="$TEST_TMP_DIR/new_dir/new_file.md"
  write_markdown_file "$new_file" "New content"
  approve "cat \"$new_file\"" "write_markdown_file_create_new"

# Cleanup
rm -rf "$TEST_TMP_DIR"
