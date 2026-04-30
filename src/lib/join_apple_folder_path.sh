join_apple_folder_path() {
	local base_folder="$1"
	local relative_dir="$2"
	local result=""

	if [ -n "$base_folder" ]; then
		result="$base_folder"
	fi

	if [ -n "$relative_dir" ] && [ "$relative_dir" != "." ]; then
		local normalized_dir
		normalized_dir=$(printf '%s' "$relative_dir" | sed 's#^\./##')
		normalized_dir=${normalized_dir//\//:}
		if [ -n "$result" ]; then
			result="$result:$normalized_dir"
		else
			result="$normalized_dir"
		fi
	fi

	echo "$result"
}
