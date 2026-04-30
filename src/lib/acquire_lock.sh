acquire_lock() {
	local root_dir="$1"
	lock_dir="$root_dir/.stash"
	lock_file="$lock_dir/lock"
	mkdir -p "$lock_dir"

	if [ -f "$lock_file" ]; then
		echo "Error: Sync lock exists: $lock_file" >&2
		return 1
	fi

	echo "$$" > "$lock_file"
	echo "$lock_file"
}
