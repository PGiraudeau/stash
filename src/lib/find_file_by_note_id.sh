find_file_by_note_id() {
	local root_dir="$1"
	local note_id="$2"

	[ -d "$root_dir" ] || return 1
	validate_note_id "$note_id" || return 1

	while IFS= read -r file_path; do
		content=$(read_markdown_file "$file_path") || continue
		current_id=$(get_id_from_frontmatter "$content") || true
		if [ "$current_id" = "$note_id" ]; then
			echo "$file_path"
			return 0
		fi
	done < <(find "$root_dir" -type f -name '*.md' 2>/dev/null | sort)

	return 1
}
