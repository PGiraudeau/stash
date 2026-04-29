prepare_links_for_push() {
	sed -E 's#\]\(([^):][^)]*\.md(#[^)]*)?)\)#](stash-md://\1)#g'
}
