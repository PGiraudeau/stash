read_sync_metadata() {
	local content="$1"
	local key="$2"

	printf '%s\n' "$content" | awk -v target="$key" '
		BEGIN { in_fm=0; seen_start=0 }
		/^---[[:space:]]*$/ {
			if (!seen_start) { seen_start=1; in_fm=1; next }
			if (in_fm) { exit }
		}
		in_fm {
			split($0, parts, ":")
			k=parts[1]
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
			if (k == target) {
				sub(/^[^:]+:[[:space:]]*/, "", $0)
				print
				exit
			}
		}
	'
}
