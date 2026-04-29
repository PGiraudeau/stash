sync_one_file() {
	local file_path="$1"
	local root_dir="$2"
	local base_folder="$3"
	local auto_create="$4"
	local dry_run="$5"

	echo "Reading file: $file_path"
	markdown_content=$(read_markdown_file "$file_path") || return 1
	local_body=$(echo "$markdown_content" | strip_frontmatter)
	local_hash=$(compute_content_hash "$local_body")

	note_id=$(get_id_from_frontmatter "$markdown_content") || true
	link_index=$(build_note_index "$root_dir" || true)
	note_found=""
	has_note=0
	if [ -n "$note_id" ]; then
		note_found=$(find_note "$note_id") || true
		if [ -n "$note_found" ]; then
			has_note=1
		fi
	fi

	remote_markdown=""
	remote_hash=""
	note_path=""
	if [ "$has_note" = "1" ]; then
		html_content=$(read_note "$note_found") || {
			echo "Error: Failed to read note content: $file_path" >&2
			return 1
		}
		remote_markdown=$(echo "$html_content" | html_to_markdown | restore_links_from_pull)
		remote_hash=$(compute_content_hash "$remote_markdown")
		note_path=$(get_note_folder_path "$note_found" || true)
	fi

	last_local_hash=$(read_sync_metadata "$markdown_content" "stash_last_local_hash")
	last_remote_hash=$(read_sync_metadata "$markdown_content" "stash_last_remote_hash")

	action=$(resolve_sync_action "$local_hash" "$remote_hash" "$last_local_hash" "$last_remote_hash" "$has_note")
	echo "Action: $action ($file_path)"

	if [ "$dry_run" = "1" ] || [ "$dry_run" = "true" ]; then
		return 0
	fi

	case "$action" in
		create_note)
			if [[ "$auto_create" != "1" && "$auto_create" != "true" && "$auto_create" != "yes" ]]; then
				echo "Note not found in Apple Notes. Create new note? (y/n)"
				read -r response
				if [[ ! "$response" =~ ^[Yy]$ ]]; then
					echo "Operation cancelled"
					return 0
				fi
			fi

			relative_dir=$(dirname "${file_path#$root_dir/}")
			target_folder=$(join_apple_folder_path "$base_folder" "$relative_dir")
			html_content=$(echo "$local_body" | prepare_links_for_push "$file_path" "$root_dir" "$link_index" | markdown_to_html)
			new_note_id=$(create_note "$html_content" "$target_folder") || return 1
			updated_content=$(update_frontmatter "$markdown_content" "$new_note_id")
			now=$(now_utc_iso8601)
			updated_content=$(update_sync_metadata "$updated_content" "$now" "$local_hash" "$local_hash" "$target_folder")
			write_markdown_file "$file_path" "$updated_content" || return 1
			echo "Note created: $new_note_id"
			;;
		push)
			html_content=$(echo "$local_body" | prepare_links_for_push "$file_path" "$root_dir" "$link_index" | markdown_to_html)
			update_note "$note_found" "$html_content" || return 1
			now=$(now_utc_iso8601)
			updated_content=$(update_sync_metadata "$markdown_content" "$now" "$local_hash" "$local_hash" "$note_path")
			write_markdown_file "$file_path" "$updated_content" || return 1
			echo "Pushed local changes"
			;;
		pull)
			now=$(now_utc_iso8601)
			updated_body="$remote_markdown"
			updated_content=$(printf '%s\n\n%s' "$(echo "$markdown_content" | extract_frontmatter)" "$updated_body")
			updated_content=$(update_sync_metadata "$updated_content" "$now" "$remote_hash" "$remote_hash" "$note_path")
			write_markdown_file "$file_path" "$updated_content" || return 1
			echo "Pulled remote changes"
			;;
		bootstrap_metadata)
			now=$(now_utc_iso8601)
			updated_content=$(update_sync_metadata "$markdown_content" "$now" "$local_hash" "$remote_hash" "$note_path")
			write_markdown_file "$file_path" "$updated_content" || return 1
			echo "Metadata initialized"
			;;
		noop)
			echo "No changes"
			;;
		conflict)
			if [ "$has_note" != "1" ]; then
				echo "Error: Cannot create conflict without remote note: $file_path" >&2
				return 1
			fi
			conflict_file=$(write_conflict_file "$file_path" "$local_body" "$remote_markdown")
			echo "Conflict written: $conflict_file"
			;;
		*)
			echo "Error: Unknown sync action '$action'" >&2
			return 1
			;;
	esac
}

input_path="${args[file]}"
base_folder="${args[folder]}"
auto_create="${args[yes]}"
dry_run="${args[dry_run]}"

if [ -f "$input_path" ]; then
	root_dir=$(dirname "$input_path")
	sync_one_file "$input_path" "$root_dir" "$base_folder" "$auto_create" "$dry_run"
	exit $?
fi

if [ -d "$input_path" ]; then
	failed=0
	while IFS= read -r file_path; do
		sync_one_file "$file_path" "$input_path" "$base_folder" "$auto_create" "$dry_run" || failed=1
	done < <(find "$input_path" -type f -name '*.md' | sort)
	exit $failed
fi

echo "Error: Path not found: $input_path" >&2
exit 1
