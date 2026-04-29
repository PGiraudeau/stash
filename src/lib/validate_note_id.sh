validate_note_id() {
	local note_id="$1"

	# Apple Notes IDs are expected to be x-coredata://... URIs
	if [[ "$note_id" =~ ^x-coredata://[^[:space:]\"]+$ ]]; then
		return 0
	fi

	echo "Error: Invalid apple_notes_id format" >&2
	return 1
}
