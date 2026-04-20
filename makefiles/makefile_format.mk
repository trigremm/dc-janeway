# makefile_format.mk
# Formatters and linters for the repo. Each tool is optional — targets skip
# the step with a warning if the binary is not on PATH. Install hints:
#   npm i -g prettier
#   go install mvdan.cc/sh/v3/cmd/shfmt@latest
#   brew install hadolint  (or: docker run --rm -i hadolint/hadolint)

.PHONY: f format format-check lint

f: format

# Format all supported files in place.
format:
	@if command -v prettier >/dev/null; then \
		echo "→ prettier"; \
		git ls-files '*.md' '*.yaml' '*.yml' '*.json' | xargs -r prettier --write; \
	else \
		echo "✗ prettier not installed — skipping md/yaml/json"; \
	fi
	@if command -v shfmt >/dev/null; then \
		files=$$(git ls-files '*.sh'); \
		if [ -n "$$files" ]; then \
			echo "→ shfmt"; \
			echo "$$files" | xargs shfmt -w -i 2 -ci; \
		fi; \
	else \
		echo "✗ shfmt not installed — skipping shell scripts"; \
	fi

# Check formatting without modifying files. Exits non-zero if anything is off.
format-check:
	@if command -v prettier >/dev/null; then \
		echo "→ prettier --check"; \
		git ls-files '*.md' '*.yaml' '*.yml' '*.json' | xargs -r prettier --check; \
	else \
		echo "✗ prettier not installed — cannot check md/yaml/json"; exit 1; \
	fi

# Lint Dockerfiles (if any tracked) and shell scripts.
lint:
	@if command -v hadolint >/dev/null; then \
		files=$$(git ls-files '*Dockerfile*'); \
		if [ -n "$$files" ]; then \
			echo "→ hadolint"; \
			echo "$$files" | xargs hadolint; \
		fi; \
	else \
		echo "✗ hadolint not installed — skipping Dockerfile lint"; \
	fi
	@if command -v shellcheck >/dev/null; then \
		files=$$(git ls-files '*.sh'); \
		if [ -n "$$files" ]; then \
			echo "→ shellcheck (scripts)"; \
			echo "$$files" | xargs shellcheck; \
		fi; \
		envs=$$(git ls-files '.env*' ':!:.env'); \
		if [ -n "$$envs" ]; then \
			echo "→ shellcheck (env files)"; \
			echo "$$envs" | xargs shellcheck --shell=bash --external-sources --exclude=SC2034; \
		fi; \
	else \
		echo "✗ shellcheck not installed — skipping shell lint"; \
	fi
