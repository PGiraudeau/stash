build_note_index() {
	local root_dir="$1"

	if [ -z "$root_dir" ] || [ ! -d "$root_dir" ]; then
		return 1
	fi

	while IFS= read -r file_path; do
		content=$(read_markdown_file "$file_path") || continue
		note_id=$(get_id_from_frontmatter "$content") || true
		rel_path="${file_path#$root_dir/}"
		if [ -n "$note_id" ]; then
			printf '%s|%s\n' "$rel_path" "$note_id"
		fi
	done < <(find "$root_dir" \( -name '.*' -prune \) -o \( -type f -name '*.md' -print \) 2>/dev/null | sort)
}
