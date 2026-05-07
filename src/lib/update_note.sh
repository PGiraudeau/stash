update_note() {
	local note_id="$1"
	local html_content="$2"
	validate_note_id "$note_id" || return 1

	# Strip newlines and escape quotes for AppleScript string
	local escaped_content="${html_content//$'\n'/}"
	escaped_content="${escaped_content//\"/\\\"}"

	# Build AppleScript and pipe to osascript to avoid heredoc escaping issues
	result=$(printf 'tell application "Notes"\n  try\n    set deletedNotesFolder to folder "Recently Deleted"\n    set theNote to first note whose id is "%s"\n    set theFolder to container of theNote\n    \n    if theFolder is equal to deletedNotesFolder then\n      error "Note is in Recently Deleted"\n    end if\n    \n    set body of theNote to "%s"\n    return "%s"\n  on error errMsg\n    error errMsg\n  end try\nend tell\n' \
		"$note_id" "$escaped_content" "$note_id" | osascript 2>&1 || true)

	# Check if result matches the note_id we tried to update
	if [ "$result" = "$note_id" ]; then
		echo "$result"
		return 0
	else
		echo "Error: Failed to update note $note_id: $result" >&2
		return 1
	fi
}
