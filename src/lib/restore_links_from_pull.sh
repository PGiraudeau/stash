restore_links_from_pull() {
	local input_text
	input_text=$(cat)

	python3 - "$input_text" <<'PY'
import re
import sys

text = sys.argv[1]

pattern = re.compile(r'\]\(stash-md://([^)]+)\)')

def repl(m):
    payload = m.group(1)
    if '?note_id=' in payload:
        payload = payload.split('?note_id=', 1)[0] + (('#' + payload.split('#', 1)[1]) if '#' in payload else '')
    return f']({payload})'

sys.stdout.write(pattern.sub(repl, text))
PY
}
