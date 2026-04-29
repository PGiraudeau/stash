restore_links_from_pull() {
	sed -E 's#\]\(stash-md://([^)]+)\)#](\1)#g'
}
