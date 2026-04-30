print_action_json() {
	local file_path="$1"
	local note_id="$2"
	local action="$3"
	local status="$4"
	printf '{"file":"%s","note_id":"%s","action":"%s","status":"%s"}\n' "$file_path" "$note_id" "$action" "$status"
}
