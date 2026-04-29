prepare_links_for_push() {
	local source_file="$1"
	local root_dir="$2"
	local index_data="$3"

	if [ -z "$source_file" ] || [ -z "$root_dir" ]; then
		sed -E 's#\]\(([^):][^)]*\.md(#[^)]*)?)\)#](stash-md://\1)#g'
		return 0
	fi

	python3 - "$source_file" "$root_dir" "$index_data" <<'PY'
import re
import sys
from pathlib import Path

source_file = Path(sys.argv[1]).resolve()
root_dir = Path(sys.argv[2]).resolve()
index_data = sys.argv[3]

index = {}
for line in index_data.splitlines():
    if '|' not in line:
        continue
    rel, note_id = line.split('|', 1)
    index[rel] = note_id

text = sys.stdin.read()

pattern = re.compile(r'\]\(([^)]+)\)')

def repl(m):
    raw = m.group(1)
    if '://' in raw or raw.startswith('#'):
        return m.group(0)

    target = raw
    anchor = ''
    if '#' in raw:
        target, anchor = raw.split('#', 1)
        anchor = '#' + anchor

    if not target.endswith('.md'):
        return m.group(0)

    candidate = (source_file.parent / target).resolve()
    try:
        rel = str(candidate.relative_to(root_dir))
    except ValueError:
        return m.group(0)

    note_id = index.get(rel)
    if note_id:
        return f'](stash-md://{rel}?note_id={note_id}{anchor})'
    return f'](stash-md://{target}{anchor})'

sys.stdout.write(pattern.sub(repl, text))
PY
}
