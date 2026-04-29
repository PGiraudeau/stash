strip_frontmatter() {
	awk '
		BEGIN { skip=0; started=0 }
		NR==1 && /^---[[:space:]]*$/ { skip=1; started=1; next }
		skip && /^---[[:space:]]*$/ { skip=0; next }
		skip { next }
		{ print }
	'
}
