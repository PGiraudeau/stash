write_conflict_file() {
	local file_path="$1"
	local local_body="$2"
	local remote_body="$3"

	local conflict_path
	conflict_path="${file_path%.md}.conflict.md"

	{
		echo "# Sync Conflict"
		echo
		echo "Source file: $file_path"
		echo
		echo "## Local (Git)"
		echo
		printf '%s\n' "$local_body"
		echo
		echo "## Remote (Apple Notes)"
		echo
		printf '%s\n' "$remote_body"
	} > "$conflict_path"

	echo "$conflict_path"
}
