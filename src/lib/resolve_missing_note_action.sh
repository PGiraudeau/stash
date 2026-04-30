resolve_missing_note_action() {
	local policy="$1"

	case "$policy" in
		""|ignore)
			echo "missing_ignore"
			;;
		archive)
			echo "missing_archive"
			;;
		propagate)
			echo "create_note"
			;;
		*)
			echo "missing_ignore"
			;;
	esac
}
