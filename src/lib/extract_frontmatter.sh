extract_frontmatter() {
	awk '
		BEGIN { in_fm=0; seen_start=0 }
		/^---[[:space:]]*$/ {
			if (!seen_start) { seen_start=1; in_fm=1; print; next }
			if (in_fm) { print; exit }
		}
		in_fm { print }
	'
}
