pull_one_file() {
	local file_path="$1"
	local base_folder="$2"

	echo "Reading file: $file_path"
	markdown_content=$(read_markdown_file "$file_path")

	note_id=$(get_id_from_frontmatter "$markdown_content")
	if [ -z "$note_id" ]; then
		echo "Error: No apple_notes_id found in frontmatter: $file_path" >&2
		return 1
	fi

	echo "Searching for note..."
	if ! find_note "$note_id" > /dev/null; then
		echo "Error: Note not found in Apple Notes: $file_path" >&2
		return 1
	fi

	if [ -n "$base_folder" ]; then
		note_folder_path=$(get_note_folder_path "$note_id") || {
			echo "Error: Failed to resolve note folder path: $file_path" >&2
			return 1
		}
		case "$note_folder_path" in
			"$base_folder"|"$base_folder":*) ;;
			*)
				echo "Error: Note is outside base folder '$base_folder': $file_path" >&2
				return 1
				;;
		esac
	fi

	echo "Reading note content..."
	html_content=$(read_note "$note_id")
	if [ -z "$html_content" ]; then
		echo "Error: Failed to read note content: $file_path" >&2
		return 1
	fi

	markdown_body=$(echo "$html_content" | html_to_markdown | restore_links_from_pull "$file_path" "$(dirname "$file_path")")
	frontmatter=$(echo "$markdown_content" | extract_frontmatter)
	updated_content=$(printf '%s\n\n%s' "$frontmatter" "$markdown_body")
	write_markdown_file "$file_path" "$updated_content"
	echo "File updated: $file_path"
}

input_path="${args[file]}"
base_folder="${args[folder]}"

if [ -f "$input_path" ]; then
	pull_one_file "$input_path" "$base_folder"
	exit $?
fi

if [ -d "$input_path" ]; then
	failed=0
	while IFS= read -r file_path; do
		pull_one_file "$file_path" "$base_folder" || failed=1
	done < <(find "$input_path" -type f -name '*.md' | sort)
	exit $failed
fi

echo "Error: Path not found: $input_path" >&2
exit 1
