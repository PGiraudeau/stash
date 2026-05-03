update_frontmatter() {
	local content="$1"
	local apple_notes_id="$2"
	local current_frontmatter
	local current_body
	local preserved_frontmatter

	current_frontmatter=$(printf '%s\n' "$content" | extract_frontmatter || true)
	current_body=$(printf '%s\n' "$content" | strip_frontmatter)

	preserved_frontmatter=$(printf '%s\n' "$current_frontmatter" | grep -v '^[[:space:]]*apple_notes_id:' | grep -v '^---[[:space:]]*$' || true)
	preserved_frontmatter=$(printf '%s\n' "$preserved_frontmatter" | sed '/^[[:space:]]*$/d')

	{
		echo "---"
		if [ -n "$preserved_frontmatter" ]; then
			printf '%s\n' "$preserved_frontmatter"
		fi
		echo "apple_notes_id: $apple_notes_id"
		echo "---"
		echo
		printf '%s\n' "$current_body"
	}
}
