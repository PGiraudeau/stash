get_id_from_frontmatter() {
	local content="$1"
	local id

	id=$(printf '%s\n' "$content" | awk '
		BEGIN { in_fm=0; seen_start=0 }
		/^---[[:space:]]*$/ {
			if (!seen_start) { seen_start=1; in_fm=1; next }
			if (in_fm) { in_fm=0; exit }
		}
		in_fm && /^apple_notes_id:[[:space:]]*/ {
			sub(/^apple_notes_id:[[:space:]]*/, "", $0)
			print
			exit
		}
	')

	if [ -z "$id" ]; then
		return 1
	fi

	echo "$id"
	return 0
}
