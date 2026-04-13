# dc-janeway

Thin deployment wrapper around [Janeway](https://github.com/BirkbeckCTP/janeway) — the Django-based open-source scholarly publishing platform from Birkbeck, University of London.

Unlike `dc-ojs`, this repo does **not** ship its own `docker-compose.yaml`. Janeway already has a production-grade Docker setup in its own repository; we clone it into `upstream/` and wrap its Makefile with our conventions (pinned ref, `.env` workflow, nginx reverse proxy, backups).

## TL;DR

```bash
cp .env.sample .env          # edit passwords, pin JANEWAY_REF
make bootstrap               # clones BirkbeckCTP/janeway into upstream/ at pinned ref
make install                 # runs upstream installer (schema + initial press + admin)
make up                      # start containers
# open http://localhost:8090 → log in with JANEWAY_ADMIN_EMAIL / _PASSWORD
```

On crash: `make logs`; to rebuild: `make r`.

## Commands

### Upstream lifecycle

```bash
make bootstrap          # clone upstream at .env JANEWAY_REF
make update-upstream    # git fetch + checkout the pinned ref
make install            # upstream installer (first-run bootstrapping)
```

### Docker compose (proxied into upstream/)

```bash
make up                 # start containers
make stop               # stop
make down               # stop and remove
make r                  # build + stop + up
make logs               # tail logs
make ps                 # list containers
```

### Maintenance

```bash
make janeway-migrate          # run Django migrations
make janeway-createsuperuser  # create a Django superuser
make janeway-collectstatic    # collectstatic
make janeway-backup           # pg_dump into .docker_volumes/backups/
make janeway-health           # curl the landing page
```

### Shell access

```bash
make janeway-shell       # bash into web container
make janeway-db-shell    # psql
```

## Stack

- Python 3.10+
- Django 4.2
- PostgreSQL (default; `DB_VENDOR` in upstream controls MySQL/SQLite alternatives)
- Upstream provides its own gunicorn + Dockerfile; we don't touch that

## Structure

- `Makefile` / `makefiles/` — wrappers around upstream's Make targets
- `upstream/` — gitignored clone of [BirkbeckCTP/janeway](https://github.com/BirkbeckCTP/janeway), pinned by `JANEWAY_REF` in `.env`
- `x_nginx/` — host-level nginx reverse proxy configs for `janeway.asmo.su`
- `.docker_volumes/backups/` — Postgres dumps from `make janeway-backup` (gitignored)

## Why "thin wrapper"?

Janeway already ships a well-maintained `docker-compose.yml` and `Makefile` in its repo. Forking them would mean chasing upstream changes forever. Instead:

1. `.env` here drives the setup (port, DB creds, admin, pinned `JANEWAY_REF`)
2. `make bootstrap` clones upstream at the pinned ref and symlinks `.env` into `upstream/`
3. All Docker operations (`up`, `stop`, `logs`, etc.) `cd upstream && docker compose ...`
4. Upgrades: bump `JANEWAY_REF` in `.env`, `make update-upstream && make r && make janeway-migrate`

## nginx reverse proxy

Ready config in [`x_nginx/janeway.asmo.su.conf`](x_nginx/janeway.asmo.su.conf). Install:

```bash
sudo cp x_nginx/janeway.asmo.su.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/janeway.asmo.su.conf /etc/nginx/sites-enabled/
sudo certbot certonly --nginx -d janeway.asmo.su
sudo nginx -t && sudo systemctl reload nginx
```

## Security quick checklist

- [ ] Rotate `POSTGRES_PASSWORD`, `SECRET_KEY`, `JANEWAY_ADMIN_PASSWORD` in `.env`
- [ ] `chmod 600 .env`
- [ ] Generate `SECRET_KEY`: `openssl rand -hex 32`
- [ ] Set `DEBUG=0` and `ALLOWED_HOSTS=janeway.asmo.su` in `.env`
- [ ] Put nginx with TLS in front (see above)
- [ ] `make janeway-backup` on cron

## License

MIT — see upstream Janeway's license ([AGPL-3.0](https://github.com/BirkbeckCTP/janeway/blob/master/LICENSE)) for the cloned code in `upstream/`.
