restore_links_from_pull() {
	local input_text
	input_text=$(cat)

	python3 - "$input_text" <<'PY'
import re
import sys

text = sys.argv[1]

md_pattern = re.compile(r'\]\(stash-md://([^)]+)\)')
asset_pattern = re.compile(r'\]\(stash-asset://([^)]+)\)')

def md_repl(m):
    payload = m.group(1)
    return f'](stash-md://{payload})'

def asset_repl(m):
    payload = m.group(1)
    return f']({payload})'

out = md_pattern.sub(md_repl, text)
out = asset_pattern.sub(asset_repl, out)
sys.stdout.write(out)
PY
}
