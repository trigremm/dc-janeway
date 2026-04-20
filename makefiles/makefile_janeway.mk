# makefile_janeway.mk
# Janeway runtime + source-tree management.
#
# Flow on a fresh host:
#   1) make janeway-install   — clones BirkbeckCTP/janeway into backend/janeway/
#   2) make build             — Dockerfile pip-installs from that requirements.txt
#   3) make up                — source is bind-mounted; entrypoint runs migrations + gunicorn
#   4) make janeway-setup     — run install_janeway (initial press + admin)

JANEWAY_REPO := https://github.com/BirkbeckCTP/janeway.git
JANEWAY_SRC  := backend/janeway

DB_SERVICE   := db
APP_SERVICE  := janeway

# Janeway's manage.py lives at /app/src inside the container (image WORKDIR is /app).
EXEC_APP     := $(DC_BIN) exec -w /app/src $(APP_SERVICE)
EXEC_APP_T   := $(DC_BIN) exec -T -w /app/src $(APP_SERVICE)

.PHONY: janeway-install janeway-update janeway-clean
.PHONY: janeway-setup janeway-migrate janeway-collectstatic janeway-createsuperuser
.PHONY: janeway-shell janeway-db-shell
.PHONY: janeway-backup janeway-restore janeway-health

# Ensure the source tree + bind-mount targets exist before docker operations.
# janeway-install is idempotent — no-ops once the clone exists.
build: janeway-install
up: janeway-install

# Clone Janeway source into the bind-mount path at the pinned JANEWAY_REF,
# and pre-create bind-mount targets so Docker doesn't create them as root.
# appuser (uid 1000 in the image) must be able to write to media/.
janeway-install:
	@mkdir -p .docker_volumes/media .docker_volumes/backups
	@$(LOAD_ENV); \
	if [ -d $(JANEWAY_SRC)/.git ]; then \
		echo "$(JANEWAY_SRC) already exists. Use 'make janeway-update' to sync."; \
		exit 0; \
	fi; \
	echo "Cloning Janeway at $${JANEWAY_REF}..."; \
	git clone $(JANEWAY_REPO) $(JANEWAY_SRC); \
	cd $(JANEWAY_SRC) && git checkout "$${JANEWAY_REF}"
	@echo "Next: make build && make up && make janeway-setup"

# Bump JANEWAY_REF in .env, then run this to fast-forward the clone.
janeway-update:
	@$(LOAD_ENV); cd $(JANEWAY_SRC) && git fetch --tags && git checkout "$${JANEWAY_REF}"

janeway-clean:
	rm -rf $(JANEWAY_SRC)

# First-run bootstrap inside the app container. Safe to skip if already done
# (install_janeway detects an existing install).
janeway-setup:
	$(EXEC_APP) python manage.py install_janeway

janeway-migrate:
	$(EXEC_APP_T) python manage.py migrate

janeway-collectstatic:
	$(EXEC_APP_T) python manage.py collectstatic --noinput

janeway-createsuperuser:
	$(EXEC_APP) python manage.py createsuperuser

janeway-shell:
	$(EXEC_APP) bash

janeway-db-shell:
	@$(LOAD_ENV); $(DC_BIN) exec -e PGPASSWORD="$$POSTGRES_PASSWORD" $(DB_SERVICE) psql -U "$$POSTGRES_USER" "$$POSTGRES_DB"

janeway-backup:
	@mkdir -p .docker_volumes/backups
	@$(LOAD_ENV); ts=$$(date +%Y%m%d-%H%M%S); \
	$(DC_BIN) exec -T -e PGPASSWORD="$$POSTGRES_PASSWORD" $(DB_SERVICE) \
		pg_dump -U "$$POSTGRES_USER" "$$POSTGRES_DB" > .docker_volumes/backups/db-$$ts.sql && \
	echo "Backup saved: .docker_volumes/backups/db-$$ts.sql"

janeway-restore:
	@latest=$$(ls -t .docker_volumes/backups/db-*.sql 2>/dev/null | head -1); \
	if [ -z "$$latest" ]; then echo "No backup found in .docker_volumes/backups/"; exit 1; fi; \
	echo "Restoring from $$latest"; \
	$(LOAD_ENV); $(DC_BIN) exec -T -e PGPASSWORD="$$POSTGRES_PASSWORD" $(DB_SERVICE) \
		psql -U "$$POSTGRES_USER" "$$POSTGRES_DB" < $$latest

janeway-health:
	@$(LOAD_ENV); curl -fsS "http://localhost:$${DC_JANEWAY_HTTP_PORT:-8090}/" >/dev/null && echo "OK" || echo "FAIL"
