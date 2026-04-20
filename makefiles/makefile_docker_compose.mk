# makefile_docker_compose.mk
export

BACKEND_SERVICE := janeway
SHELL := bash

DC_BIN ?= $(shell command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

# Helper: sources .env into the current recipe invocation.
LOAD_ENV := set -a; [ -f .env ] && . ./.env; set +a

.DEFAULT_GOAL := ps

.PHONY: d deploy r recreate rl
.PHONY: ps logs build up stop down restart config
.PHONY: rb lb rbs
.PHONY: shell runshell

# shortcuts
d: deploy
r: recreate
l: logs
rl: r l
rb: build-$(BACKEND_SERVICE) stop-$(BACKEND_SERVICE) up-$(BACKEND_SERVICE) ps
lb: logs-$(BACKEND_SERVICE)
rbs: rb shell

deploy: git-pull recreate docker-image-prune docker-builder-prune

recreate: build down up ps

ps:
	$(DC_BIN) ps

logs:
	$(DC_BIN) logs -f -n 100

build:
	$(DC_BIN) build

up:
	$(DC_BIN) up -d

stop:
	$(DC_BIN) stop

down:
	$(DC_BIN) down --remove-orphans

restart: stop up

config:
	$(DC_BIN) config

logs-%:
	$(DC_BIN) logs -f -n 100 $*

build-%:
	$(DC_BIN) build $*

up-%:
	$(DC_BIN) up -d $*

stop-%:
	$(DC_BIN) stop $*

shell:
	$(DC_BIN) exec $(BACKEND_SERVICE) bash

runshell:
	$(DC_BIN) run --rm $(BACKEND_SERVICE) bash
