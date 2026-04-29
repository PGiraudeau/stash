push_one_file() {
	local file_path="$1"
	local root_dir="$2"
	local base_folder="$3"
	local auto_create="$4"

	echo "Reading file: $file_path"
	markdown_content=$(read_markdown_file "$file_path")

	note_id=$(get_id_from_frontmatter "$markdown_content") || true

	note_found=""
	if [ -n "$note_id" ]; then
		echo "Searching for note..."
		note_found=$(find_note "$note_id") || true
	fi

	if [ -z "$note_found" ]; then
		echo "Note not found in Apple Notes."
		if [[ "$auto_create" != "1" && "$auto_create" != "true" && "$auto_create" != "yes" ]]; then
			echo "Create new note? (y/n)"
			read -r response
			if [[ ! "$response" =~ ^[Yy]$ ]]; then
				echo "Operation cancelled"
				return 0
			fi
		fi

		echo "Creating note..."
		relative_dir=$(dirname "${file_path#$root_dir/}")
		target_folder=$(join_apple_folder_path "$base_folder" "$relative_dir")
		html_content=$(echo "$markdown_content" | strip_frontmatter | prepare_links_for_push | markdown_to_html)

		new_note_id=$(create_note "$html_content" "$target_folder")
		if [ -z "$new_note_id" ]; then
			echo "Error: Failed to create note" >&2
			return 1
		fi

		updated_content=$(update_frontmatter "$markdown_content" "$new_note_id")
		write_markdown_file "$file_path" "$updated_content"
		echo "Note created: $new_note_id"
	else
		echo "Updating note..."
		html_content=$(echo "$markdown_content" | strip_frontmatter | prepare_links_for_push | markdown_to_html)
		if ! update_note "$note_found" "$html_content"; then
			echo "Error: Failed to update note" >&2
			return 1
		fi
		echo "Note updated: $note_found"
	fi
}

input_path="${args[file]}"
base_folder="${args[folder]}"
auto_create="${args[yes]}"

if [ -f "$input_path" ]; then
	root_dir=$(dirname "$input_path")
	push_one_file "$input_path" "$root_dir" "$base_folder" "$auto_create"
	exit $?
fi

if [ -d "$input_path" ]; then
	failed=0
	while IFS= read -r file_path; do
		push_one_file "$file_path" "$input_path" "$base_folder" "$auto_create" || failed=1
	done < <(find "$input_path" -type f -name '*.md' | sort)
	exit $failed
fi

echo "Error: Path not found: $input_path" >&2
exit 1
