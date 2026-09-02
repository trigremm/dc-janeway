# dc-janeway

Docker Compose deployment of [Janeway](https://github.com/BirkbeckCTP/janeway) — the Django-based open-source scholarly publishing platform from Birkbeck, University of London.

Self-contained: ships its own `docker-compose.yaml`, `backend/Dockerfile`, and `backend/entrypoint.sh`. Janeway source is cloned on the host under `backend/janeway/` (editable, live-bound into the container), pinned by `JANEWAY_REF` in `.env`.

## TL;DR

```bash
cp .env.sample .env               # set POSTGRES_PASSWORD, SECRET_KEY, ALLOWED_HOSTS
make janeway-install              # clone BirkbeckCTP/janeway into backend/janeway/
make build                        # pip install Janeway's deps into the image
make up                           # start db + janeway (entrypoint runs migrations)
make janeway-setup                # install_janeway (initial press + admin)
make janeway-createsuperuser
make janeway-collectstatic        # REQUIRED once — see "Static assets" below
# open http://localhost:8090
```

> **Static assets — run `make janeway-collectstatic` once after first `up`.**
> The container entrypoint no longer runs `collectstatic` on boot (it is gated
> behind `RUN_COLLECTSTATIC`, default OFF), and nginx serves `/static/` straight
> off disk from `backend/janeway/src/collected-static/`. Until that directory is
> populated, every `/static/` asset 404s. Re-run it after any static-affecting
> Janeway upgrade (already listed in [Upgrading Janeway](#upgrading-janeway)).

## Stack

- Python 3.10 (slim-bookworm)
- Django + gunicorn (3 workers by default)
- PostgreSQL 16

## Commands

### Docker Compose

| Target                                                | What it does                                |
| ----------------------------------------------------- | ------------------------------------------- |
| `make up` / `stop` / `down` / `ps` / `logs` / `build` | wrappers around `docker compose`            |
| `make r` (recreate)                                   | build + down + up                           |
| `make rl`                                             | recreate + tail logs                        |
| `make shell`                                          | bash into the `janeway` container           |
| `make deploy`                                         | `git pull` + recreate + image/builder prune |

### Janeway runtime

| Target                         | What it does                                                                                                                                                      |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `make janeway-install`         | host: clone BirkbeckCTP/janeway into `backend/janeway/` at `JANEWAY_REF`                                                                                          |
| `make janeway-update`          | host: fetch + checkout new `JANEWAY_REF` in the existing clone                                                                                                    |
| `make janeway-setup`           | container: run `install_janeway` (initial press + admin)                                                                                                          |
| `make janeway-migrate`         | `python manage.py migrate`                                                                                                                                        |
| `make janeway-createsuperuser` | Django superuser prompt                                                                                                                                           |
| `make janeway-collectstatic`   | `collectstatic --noinput` — **required once after first `up`** (boot no longer collects; nginx serves `/static/` off disk) and after any static-affecting upgrade |
| `make janeway-shell`           | bash in app container                                                                                                                                             |
| `make janeway-db-shell`        | psql against the db service                                                                                                                                       |
| `make janeway-backup`          | `pg_dump` into `.docker_volumes/backups/`                                                                                                                         |
| `make janeway-restore`         | restore most recent backup                                                                                                                                        |
| `make janeway-health`          | curl the host-proxied port                                                                                                                                        |

### nginx (public-facing host, not the container)

| Target                              | What it does                                        |
| ----------------------------------- | --------------------------------------------------- |
| `make nginx-add-janeway-asmo-su`    | deploy vhost + certbot-issued cert + HTTPS redirect |
| `make nginx-remove-janeway-asmo-su` | remove vhost, reload                                |
| `make nginx-status`                 | show enabled/available state for tracked vhosts     |

### Bootstrap helpers

| Target              | What it prints                                         |
| ------------------- | ------------------------------------------------------ |
| `make howto-deploy` | copy-paste SSH-key + clone commands for a fresh host   |
| `make howto-up`     | copy-paste `.env` setup + `make up` + install commands |

## Structure

- `docker-compose.yaml` — `db` (postgres:16) + `janeway` (our built image) services
- `backend/Dockerfile` — Python + system libs, pip installs deps from `backend/janeway/requirements.txt`
- `backend/entrypoint.sh` — migrations (`JANEWAY_MIGRATE_ON_BOOT`, default on), optional `collectstatic` (`RUN_COLLECTSTATIC`, default off), then gunicorn (`GUNICORN_WORKERS`, default 3) or `runserver` when `JANEWAY_HOT_RELOAD=true`
- `backend/janeway/` — Janeway source clone (gitignored; populated by `make janeway-install`)
- `config/janeway_local_settings.py` — bind-mounted Django settings overrides
- `makefiles/` — fragments by topic, all explicitly included in the root `Makefile`
- `x_nginx/` — host-level nginx vhost for `janeway.asmo.su` (HTTP-only; certbot adds TLS)
- `.docker_volumes/` — bind-mounted volumes (gitignored): `db/`, `media/`, `backups/`; collected static lives in `backend/janeway/src/collected-static/`

## Customising Janeway

The entire Janeway tree is at `backend/janeway/` on the host — edit freely. Container sees changes live via bind mount. For Python source changes set `JANEWAY_HOT_RELOAD=true` in `.env` to use `runserver`, or restart the container for gunicorn to pick them up.

## Upgrading Janeway

1. Bump `JANEWAY_REF` in `.env`
2. `make janeway-update` — fetch + checkout the new ref in `backend/janeway/`
3. `make build && make r` — rebuild image with the new `requirements.txt`
4. `make janeway-migrate && make janeway-collectstatic` (collectstatic is required — nginx serves `/static/` off disk and boot no longer collects)

## Security checklist

- [ ] `SECRET_KEY` generated with `openssl rand -hex 32`
- [ ] `POSTGRES_PASSWORD` rotated from the sample default
- [ ] `DEBUG=0` and `ALLOWED_HOSTS=janeway.asmo.su` for production
- [ ] `chmod 600 .env`
- [ ] nginx + Let's Encrypt in front (`make nginx-add-janeway-asmo-su`)
- [ ] `make janeway-backup` scheduled via cron

## License

Upstream Janeway is [AGPL-3.0](https://github.com/BirkbeckCTP/janeway/blob/master/LICENSE); this wrapper is MIT.
