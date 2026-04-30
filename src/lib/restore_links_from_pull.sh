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
    return f']({payload})'

sys.stdout.write(pattern.sub(repl, text))
PY
}
