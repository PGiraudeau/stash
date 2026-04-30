archive_local_file() {
	local file_path="$1"
	local archived_path="${file_path%.md}.archived.md"
	cp "$file_path" "$archived_path"
	echo "$archived_path"
}
