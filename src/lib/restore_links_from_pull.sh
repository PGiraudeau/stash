restore_links_from_pull() {
	local source_file="$1"
	local root_dir="$2"
	local input_text
	input_text=$(cat)

	python3 - "$source_file" "$root_dir" "$input_text" <<'PY'
import os
import re
import sys
from pathlib import Path

source_file = Path(sys.argv[1]).resolve()
root_dir = Path(sys.argv[2]).resolve()
text = sys.argv[3]

md_pattern = re.compile(r'\]\(stash-md://([^)]+)\)')
asset_pattern = re.compile(r'\]\(stash-asset://([^)]+)\)')

def relative_to_source(root_rel_path):
    target = (root_dir / root_rel_path).resolve()
    try:
        rel = os.path.relpath(str(target), str(source_file.parent.resolve()))
        return rel
    except ValueError:
        return root_rel_path

def md_repl(m):
    payload = m.group(1)
    anchor = ''
    if '#?' in payload:
        path, rest = payload.split('#?', 1)
        anchor = '#' + rest
    elif '#' in payload:
        path, rest = payload.split('#', 1)
        if '?note_id=' in rest:
            anchor = ''
        else:
            anchor = '#' + rest
    else:
        path = payload

    if '?note_id=' in path:
        path = path.split('?note_id=', 1)[0]

    rel = relative_to_source(path)
    return f']({rel}{anchor})'

def asset_repl(m):
    payload = m.group(1)
    anchor = ''
    if '#' in payload:
        payload, anchor_part = payload.split('#', 1)
        anchor = '#' + anchor_part
    rel = relative_to_source(payload)
    return f']({rel}{anchor})'

out = md_pattern.sub(md_repl, text)
out = asset_pattern.sub(asset_repl, out)
sys.stdout.write(out)
PY
}
