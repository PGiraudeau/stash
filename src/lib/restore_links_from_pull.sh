restore_links_from_pull() {
	python3 - <<'PY'
import re
import sys

text = sys.stdin.read()

pattern = re.compile(r'\]\(stash-md://([^)]+)\)')

def repl(m):
    payload = m.group(1)
    if '?note_id=' in payload:
        payload = payload.split('?note_id=', 1)[0] + (('#' + payload.split('#', 1)[1]) if '#' in payload else '')
    return f']({payload})'

sys.stdout.write(pattern.sub(repl, text))
PY
}
