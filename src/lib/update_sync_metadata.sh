update_sync_metadata() {
	local content="$1"
	local synced_at="$2"
	local local_hash="$3"
	local remote_hash="$4"
	local note_path="$5"

	local frontmatter
	local body
	local preserved

	frontmatter=$(printf '%s\n' "$content" | extract_frontmatter || true)
	body=$(printf '%s\n' "$content" | strip_frontmatter)

	preserved=$(printf '%s\n' "$frontmatter" | grep -v '^---[[:space:]]*$' | \
		grep -v '^[[:space:]]*stash_last_synced_at:' | \
		grep -v '^[[:space:]]*stash_last_local_hash:' | \
		grep -v '^[[:space:]]*stash_last_remote_hash:' | \
		grep -v '^[[:space:]]*stash_note_path:' || true)
	preserved=$(printf '%s\n' "$preserved" | sed '/^[[:space:]]*$/d')

	{
		echo "---"
		if [ -n "$preserved" ]; then
			printf '%s\n' "$preserved"
		fi
		echo "stash_last_synced_at: $synced_at"
		echo "stash_last_local_hash: $local_hash"
		echo "stash_last_remote_hash: $remote_hash"
		if [ -n "$note_path" ]; then
			echo "stash_note_path: $note_path"
		fi
		echo "---"
		echo
		printf '%s\n' "$body"
	}
}
