# makefiles/janeway.mk
# Thin wrapper around upstream BirkbeckCTP/janeway Docker setup.

JANEWAY_REPO := https://github.com/BirkbeckCTP/janeway.git
JANEWAY_DIR  := upstream

.PHONY: bootstrap update-upstream install janeway-shell janeway-db-shell
.PHONY: janeway-migrate janeway-createsuperuser janeway-collectstatic
.PHONY: janeway-backup janeway-restore janeway-health

# One-time setup: clone upstream at the pinned ref.
bootstrap:
	@if [ -d $(JANEWAY_DIR)/.git ]; then \
		echo "upstream already cloned. Use 'make update-upstream' to sync."; \
	else \
		$(LOAD_ENV); \
		echo "Cloning Janeway at $${JANEWAY_REF}..."; \
		git clone $(JANEWAY_REPO) $(JANEWAY_DIR); \
		cd $(JANEWAY_DIR) && git checkout "$${JANEWAY_REF}"; \
		ln -sf ../.env .env; \
	fi
	@echo "Next: make install"

# Pull upstream and checkout the pinned ref from .env.
update-upstream:
	@$(LOAD_ENV); \
	cd $(JANEWAY_DIR) && git fetch --tags && git checkout "$${JANEWAY_REF}"

# Run Janeway's bundled installer (creates DB schema, initial press, admin).
install:
	cd $(JANEWAY_DIR) && $(MAKE) install

# Shell access
janeway-shell:
	cd $(JANEWAY_DIR) && $(DC_BIN) exec janeway-web bash

janeway-db-shell:
	@$(LOAD_ENV); cd $(JANEWAY_DIR) && $(DC_BIN) exec -e PGPASSWORD="$$POSTGRES_PASSWORD" janeway-postgres psql -U "$$POSTGRES_USER" "$$POSTGRES_DB"

# Django management commands
janeway-migrate:
	cd $(JANEWAY_DIR) && $(DC_BIN) exec janeway-web python src/manage.py migrate

janeway-createsuperuser:
	cd $(JANEWAY_DIR) && $(DC_BIN) exec janeway-web python src/manage.py createsuperuser

janeway-collectstatic:
	cd $(JANEWAY_DIR) && $(DC_BIN) exec janeway-web python src/manage.py collectstatic --noinput

# Backup Postgres dump + files volume into .docker_volumes/backups/.
janeway-backup:
	@mkdir -p .docker_volumes/backups
	@$(LOAD_ENV); ts=$$(date +%Y%m%d-%H%M%S); \
	cd $(JANEWAY_DIR) && $(DC_BIN) exec -T -e PGPASSWORD="$$POSTGRES_PASSWORD" janeway-postgres \
		pg_dump -U "$$POSTGRES_USER" "$$POSTGRES_DB" > ../.docker_volumes/backups/db-$$ts.sql && \
	echo "Backup saved: .docker_volumes/backups/db-$$ts.sql"

# Quick health check — hit the landing page through the host port.
janeway-health:
	@$(LOAD_ENV); curl -fsS "http://localhost:$${DC_JANEWAY_HTTP_PORT:-8090}/" >/dev/null && echo "OK" || echo "FAIL"
