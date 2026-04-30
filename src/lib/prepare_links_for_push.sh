prepare_links_for_push() {
	local source_file="$1"
	local root_dir="$2"
	local index_data="$3"
	local input_text
	input_text=$(cat)

	if [ -z "$source_file" ] || [ -z "$root_dir" ]; then
		python3 - "$index_data" "$input_text" <<'PY'
import re
import sys

text = sys.argv[2]

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

    if target.endswith('.md'):
        return f'](stash-md://{target}{anchor})'

    return f'](stash-asset://{target}{anchor})'

sys.stdout.write(pattern.sub(repl, text))
PY
		return 0
	fi

	python3 - "$source_file" "$root_dir" "$index_data" "$input_text" <<'PY'
import re
import sys
from pathlib import Path

source_file = Path(sys.argv[1]).resolve()
root_dir = Path(sys.argv[2]).resolve()
index_data = sys.argv[3]
text = sys.argv[4]

index = {}
for line in index_data.splitlines():
    if '|' not in line:
        continue
    rel, note_id = line.split('|', 1)
    index[rel] = note_id

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

    candidate = (source_file.parent / target).resolve()
    try:
        rel = str(candidate.relative_to(root_dir))
    except ValueError:
        return m.group(0)

    if target.endswith('.md'):
        note_id = index.get(rel)
        if note_id:
            return f'](stash-md://{rel}?note_id={note_id}{anchor})'
        return f'](stash-md://{target}{anchor})'

    return f'](stash-asset://{rel}{anchor})'

sys.stdout.write(pattern.sub(repl, text))
PY
}
