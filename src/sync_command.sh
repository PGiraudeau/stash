slugify_note_name() {
	local name="$1"
	local slug
	slug=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
	[ -n "$slug" ] || slug="untitled-note"
	echo "$slug"
}

short_note_id() {
	local note_id="$1"
	printf '%s' "$note_id" | sed -E 's#^.*/##' | tr -cd '[:alnum:]' | cut -c1-8
}

unique_target_file_for_note() {
	local target_file="$1"
	local note_id="$2"

	if [ ! -f "$target_file" ]; then
		echo "$target_file"
		return 0
	fi

	local existing
	existing=$(read_markdown_file "$target_file" 2>/dev/null || true)
	local existing_id
	existing_id=$(get_id_from_frontmatter "$existing" 2>/dev/null || true)
	if [ "$existing_id" = "$note_id" ]; then
		echo "$target_file"
		return 0
	fi

	local base ext suffix
	base="${target_file%.md}"
	ext=".md"
	suffix=$(short_note_id "$note_id")
	if [ -n "$suffix" ]; then
		echo "${base}-${suffix}${ext}"
	else
		echo "${base}-remote${ext}"
	fi
}

materialize_remote_tree() {
	local root_dir="$1"
	local base_folder="$2"
	local dry_run="$3"
	local json_output="$4"

	remote_rows=$(list_notes_in_folder "$base_folder" || true)
	[ -n "$remote_rows" ] || return 0

	while IFS= read -r row; do
		[ -n "$row" ] || continue
		note_id=$(printf '%s' "$row" | cut -d'|' -f1)
		note_path=$(printf '%s' "$row" | cut -d'|' -f2)
		note_name=$(printf '%s' "$row" | cut -d'|' -f3-)
		validate_note_id "$note_id" || continue

		existing_file=$(find_file_by_note_id "$root_dir" "$note_id" || true)
		if [ -n "$existing_file" ]; then
			continue
		fi

		rel_dir="$note_path"
		if [ -n "$base_folder" ]; then
			case "$note_path" in
				"$base_folder") rel_dir="" ;;
				"$base_folder":*) rel_dir="${note_path#${base_folder}:}" ;;
				*) rel_dir="$note_path" ;;
			esac
		fi

		rel_dir_fs=$(printf '%s' "$rel_dir" | tr ':' '/')
		file_name="$(slugify_note_name "$note_name").md"
		if [ -n "$rel_dir_fs" ]; then
			target_dir="$root_dir/$rel_dir_fs"
		else
			target_dir="$root_dir"
		fi
		target_file="$target_dir/$file_name"
		target_file=$(unique_target_file_for_note "$target_file" "$note_id")

		action="materialize_remote"
		if [ "$json_output" = "1" ] || [ "$json_output" = "true" ]; then
			print_action_json "$target_file" "$note_id" "$action" "planned"
		fi
		log_action "$root_dir" "{\"file\":\"$target_file\",\"note_id\":\"$note_id\",\"action\":\"$action\",\"dry_run\":\"$dry_run\"}"

		if [ "$dry_run" = "1" ] || [ "$dry_run" = "true" ]; then
			continue
		fi

		mkdir -p "$target_dir" || return 1
		html_content=$(read_note "$note_id") || continue
		remote_markdown=$(echo "$html_content" | html_to_markdown | restore_links_from_pull)
		remote_hash=$(compute_content_hash "$remote_markdown")
		now=$(now_utc_iso8601)
		content=$(printf '%s\n' "---")
		content+=$(printf '%s\n' "apple_notes_id: $note_id")
		content+=$(printf '%s\n' "stash_last_synced_at: $now")
		content+=$(printf '%s\n' "stash_last_local_hash: $remote_hash")
		content+=$(printf '%s\n' "stash_last_remote_hash: $remote_hash")
		content+=$(printf '%s\n' "stash_note_path: $note_path")
		content+=$(printf '%s\n\n' "---")
		content+=$(printf '%s\n' "$remote_markdown")
		write_markdown_file "$target_file" "$content" || return 1
		echo "Materialized remote note: $target_file"
		if [ "$json_output" = "1" ] || [ "$json_output" = "true" ]; then
			print_action_json "$target_file" "$note_id" "$action" "applied"
		fi
	done <<< "$remote_rows"
}

sync_one_file() {
	local file_path="$1"
	local root_dir="$2"
	local base_folder="$3"
	local auto_create="$4"
	local dry_run="$5"
	local json_output="$6"
	local deletion_policy="$7"
	local mirror_path="$8"

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
	last_note_path=$(read_sync_metadata "$markdown_content" "stash_note_path")

	action=$(resolve_sync_action "$local_hash" "$remote_hash" "$last_local_hash" "$last_remote_hash" "$has_note")
	if [ "$has_note" = "0" ] && [ -n "$note_id" ]; then
		action=$(resolve_missing_note_action "$deletion_policy")
	fi
	echo "Action: $action ($file_path)"
	if [ "$json_output" = "1" ] || [ "$json_output" = "true" ]; then
		print_action_json "$file_path" "$note_id" "$action" "planned"
	fi
	log_action "$root_dir" "{\"file\":\"$file_path\",\"action\":\"$action\",\"dry_run\":\"$dry_run\"}"

	if [ "$has_note" = "1" ] && [ -n "$last_note_path" ] && [ "$last_note_path" != "$note_path" ]; then
		echo "Detected remote folder move: $last_note_path -> $note_path"
		log_action "$root_dir" "{\"file\":\"$file_path\",\"note_id\":\"$note_id\",\"action\":\"remote_path_changed\",\"from\":\"$last_note_path\",\"to\":\"$note_path\"}"
	fi

	if [ "$dry_run" = "1" ] || [ "$dry_run" = "true" ]; then
		return 0
	fi

	case "$action" in
		missing_ignore)
			echo "Missing remote note ignored by policy"
			[ "$json_output" = "1" ] || [ "$json_output" = "true" ] && print_action_json "$file_path" "$note_id" "$action" "ignored"
			;;
		missing_archive)
			archived_file=$(archive_local_file "$file_path") || return 1
			echo "Archived local file: $archived_file"
			[ "$json_output" = "1" ] || [ "$json_output" = "true" ] && print_action_json "$file_path" "$note_id" "$action" "archived"
			;;
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
			[ "$json_output" = "1" ] || [ "$json_output" = "true" ] && print_action_json "$file_path" "$new_note_id" "$action" "applied"
			;;
		push)
			html_content=$(echo "$local_body" | prepare_links_for_push "$file_path" "$root_dir" "$link_index" | markdown_to_html)
			update_note "$note_found" "$html_content" || return 1
			if [ "$mirror_path" = "1" ] || [ "$mirror_path" = "true" ]; then
				relative_dir=$(dirname "${file_path#$root_dir/}")
				target_folder=$(join_apple_folder_path "$base_folder" "$relative_dir")
				[ -n "$target_folder" ] && move_note_to_folder "$note_found" "$target_folder" >/dev/null
				note_path="$target_folder"
			fi
			now=$(now_utc_iso8601)
			updated_content=$(update_sync_metadata "$markdown_content" "$now" "$local_hash" "$local_hash" "$note_path")
			write_markdown_file "$file_path" "$updated_content" || return 1
			echo "Pushed local changes"
			[ "$json_output" = "1" ] || [ "$json_output" = "true" ] && print_action_json "$file_path" "$note_found" "$action" "applied"
			;;
		pull)
			now=$(now_utc_iso8601)
			updated_body="$remote_markdown"
			updated_content=$(printf '%s\n\n%s' "$(echo "$markdown_content" | extract_frontmatter)" "$updated_body")
			updated_content=$(update_sync_metadata "$updated_content" "$now" "$remote_hash" "$remote_hash" "$note_path")
			write_markdown_file "$file_path" "$updated_content" || return 1
			echo "Pulled remote changes"
			[ "$json_output" = "1" ] || [ "$json_output" = "true" ] && print_action_json "$file_path" "$note_found" "$action" "applied"
			;;
		bootstrap_metadata)
			now=$(now_utc_iso8601)
			updated_content=$(update_sync_metadata "$markdown_content" "$now" "$local_hash" "$remote_hash" "$note_path")
			write_markdown_file "$file_path" "$updated_content" || return 1
			echo "Metadata initialized"
			[ "$json_output" = "1" ] || [ "$json_output" = "true" ] && print_action_json "$file_path" "$note_found" "$action" "applied"
			;;
		noop)
			if [ "$has_note" = "1" ] && [ -n "$note_path" ] && [ "$last_note_path" != "$note_path" ]; then
				now=$(now_utc_iso8601)
				updated_content=$(update_sync_metadata "$markdown_content" "$now" "$local_hash" "$remote_hash" "$note_path")
				write_markdown_file "$file_path" "$updated_content" || return 1
				echo "Updated sync metadata for remote folder move"
			else
				echo "No changes"
			fi
			;;
		conflict)
			if [ "$has_note" != "1" ]; then
				echo "Error: Cannot create conflict without remote note: $file_path" >&2
				return 1
			fi
			conflict_file=$(write_conflict_file "$file_path" "$local_body" "$remote_markdown")
			echo "Conflict written: $conflict_file"
			[ "$json_output" = "1" ] || [ "$json_output" = "true" ] && print_action_json "$file_path" "$note_found" "$action" "conflict"
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
json_output="${args[json]}"
deletion_policy="${args[deletion_policy]}"
mirror_path="${args[mirror_path]}"
materialize_remote="${args[materialize_remote]}"

config_file=$(load_stash_config "$input_path" || true)
if [ -n "$config_file" ]; then
	if [ -z "$base_folder" ]; then
		base_folder=$(get_config_value "$config_file" "apple.base_folder")
	fi
	if [ -z "$dry_run" ]; then
		dry_run=$(get_config_value "$config_file" "sync.dry_run_default")
	fi
fi

if [ -f "$input_path" ]; then
	root_dir=$(dirname "$input_path")
	lock_file=$(acquire_lock "$root_dir") || exit 1
	trap 'release_lock "$lock_file"' EXIT
	sync_one_file "$input_path" "$root_dir" "$base_folder" "$auto_create" "$dry_run" "$json_output" "$deletion_policy" "$mirror_path"
	exit $?
fi

if [ -d "$input_path" ]; then
	lock_file=$(acquire_lock "$input_path") || exit 1
	trap 'release_lock "$lock_file"' EXIT
	failed=0
	if [ "$materialize_remote" = "1" ] || [ "$materialize_remote" = "true" ]; then
		materialize_remote_tree "$input_path" "$base_folder" "$dry_run" "$json_output" || failed=1
	fi
	while IFS= read -r file_path; do
		sync_one_file "$file_path" "$input_path" "$base_folder" "$auto_create" "$dry_run" "$json_output" "$deletion_policy" "$mirror_path" || failed=1
	done < <(find "$input_path" -type f -name '*.md' | sort)
	exit $failed
fi

echo "Error: Path not found: $input_path" >&2
exit 1
