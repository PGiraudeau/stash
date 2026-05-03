validate_note_id() {
	local note_id="$1"
	local pattern='^x-coredata://[^[:space:]"]+$'

	if [[ "$note_id" =~ $pattern ]]; then
		return 0
	fi

	echo "Error: Invalid apple_notes_id format" >&2
	return 1
}
