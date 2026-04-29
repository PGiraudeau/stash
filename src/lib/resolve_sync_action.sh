resolve_sync_action() {
	local local_hash="$1"
	local remote_hash="$2"
	local last_local_hash="$3"
	local last_remote_hash="$4"
	local has_note="$5"

	if [ "$has_note" != "1" ]; then
		echo "create_note"
		return 0
	fi

	if [ -z "$last_local_hash" ] || [ -z "$last_remote_hash" ]; then
		if [ "$local_hash" = "$remote_hash" ]; then
			echo "bootstrap_metadata"
		else
			echo "conflict"
		fi
		return 0
	fi

	local_changed=0
	remote_changed=0

	[ "$local_hash" != "$last_local_hash" ] && local_changed=1
	[ "$remote_hash" != "$last_remote_hash" ] && remote_changed=1

	if [ "$local_changed" = "0" ] && [ "$remote_changed" = "0" ]; then
		echo "noop"
	elif [ "$local_changed" = "1" ] && [ "$remote_changed" = "0" ]; then
		echo "push"
	elif [ "$local_changed" = "0" ] && [ "$remote_changed" = "1" ]; then
		echo "pull"
	else
		if [ "$local_hash" = "$remote_hash" ]; then
			echo "noop"
		else
			echo "conflict"
		fi
	fi
}
