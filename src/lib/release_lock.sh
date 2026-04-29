release_lock() {
	local lock_file="$1"
	if [ -n "$lock_file" ] && [ -f "$lock_file" ]; then
		rm -f "$lock_file"
	fi
}
