# makefiles/docker_compose.mk
DC_BIN := docker compose

# Helper to source .env in a recipe without exposing secrets on argv.
LOAD_ENV := set -a; [ -f .env ] && . ./.env; set +a

.PHONY: d r l rl
.PHONY: deploy recreate
.PHONY: ps logs build up stop down

# aliases
d: deploy
r: recreate
l: logs
rl: r l

deploy:
	git pull
	$(MAKE) recreate

recreate: build stop up

ps:
	cd upstream && $(DC_BIN) ps

logs:
	cd upstream && $(DC_BIN) logs -f -n 100

build:
	cd upstream && $(DC_BIN) build

up:
	cd upstream && $(DC_BIN) up -d

stop:
	cd upstream && $(DC_BIN) stop

down:
	cd upstream && $(DC_BIN) down --remove-orphans
