load_stash_config() {
	local start_path="$1"
	local dir
	local cfg

	if [ -z "$start_path" ]; then
		start_path="$(pwd)"
	fi

	if [ -f "$start_path" ]; then
		dir=$(dirname "$start_path")
	else
		dir="$start_path"
	fi

	while [ "$dir" != "/" ]; do
		cfg="$dir/.stash.yml"
		if [ -f "$cfg" ]; then
			echo "$cfg"
			return 0
		fi
		dir=$(dirname "$dir")
	done

	return 1
}

get_config_value() {
	local config_file="$1"
	local key="$2"

	if [ ! -f "$config_file" ]; then
		return 1
	fi

	case "$key" in
		apple.base_folder)
			awk '/^[[:space:]]*apple:/ {in_apple=1; next} in_apple && /^[[:space:]]*[a-zA-Z0-9_]+:/ {if ($0 !~ /^[[:space:]]+base_folder:/) in_apple=0} in_apple && /^[[:space:]]+base_folder:/ {sub(/^[^:]+:[[:space:]]*/, ""); print; exit}' "$config_file"
			;;
		sync.dry_run_default)
			awk '/^[[:space:]]*sync:/ {in_sync=1; next} in_sync && /^[[:space:]]*[a-zA-Z0-9_]+:/ {if ($0 !~ /^[[:space:]]+dry_run_default:/) in_sync=0} in_sync && /^[[:space:]]+dry_run_default:/ {sub(/^[^:]+:[[:space:]]*/, ""); print; exit}' "$config_file"
			;;
		*)
			return 1
			;;
	esac
}
