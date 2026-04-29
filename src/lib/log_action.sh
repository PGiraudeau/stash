log_action() {
	local root_dir="$1"
	local message="$2"
	local log_dir="$root_dir/.stash"
	local log_file="$log_dir/log.jsonl"
	mkdir -p "$log_dir"
	printf '%s\n' "$message" >> "$log_file"
}
