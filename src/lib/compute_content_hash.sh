compute_content_hash() {
	local content="$1"
	printf '%s' "$content" | shasum -a 256 | awk '{print $1}'
}
