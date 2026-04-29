BASHLY = docker run --rm --user $$(id -u):$$(id -g) --volume "$$PWD:/app" dannyben/bashly

.PHONY: build test test-unit smoke-local release

build:
	mkdir -p dist
	$(BASHLY) generate

test:
	test/approve

test-unit:
	SKIP_INTEGRATION=1 test/approve

smoke-local:
	@echo "Checking local runtime dependencies..."
	@command -v bash >/dev/null || (echo "Missing: bash" && exit 1)
	@command -v pandoc >/dev/null || (echo "Missing: pandoc" && exit 1)
	@command -v osascript >/dev/null || (echo "Missing: osascript (requires macOS)" && exit 1)
	@echo "Architecture: $$(uname -m)"
	@echo "bash: $$(bash --version | head -n 1)"
	@echo "pandoc: $$(pandoc --version | head -n 1)"
	@echo "osascript: available"
	@echo "Smoke check passed"

release:
	@test -n "$(VERSION)" || (echo "Usage: make release VERSION=x.y.z" && exit 1)
	perl -i -pe 's/^version:.*/version: $(VERSION)/' src/bashly.yml
	git add src/bashly.yml
	git commit -m "Bump version to $(VERSION)"
	git tag "v$(VERSION)"
	git push origin master --tags
