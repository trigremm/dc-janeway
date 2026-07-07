#!/bin/sh
set -e

cd /app/src

# Optional: run migrations on boot (disable with JANEWAY_MIGRATE_ON_BOOT=false)
case "$(echo "${JANEWAY_MIGRATE_ON_BOOT:-true}" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes)
    echo "Running migrations..."
    python manage.py migrate --noinput
    ;;
esac

# Optional: collectstatic on boot. OFF by default — re-copying thousands of
# static files on every restart is slow and rarely needed. Enable per-boot with
# RUN_COLLECTSTATIC=true, or run `make janeway-collectstatic` when assets change.
case "$(echo "${RUN_COLLECTSTATIC:-false}" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes)
    echo "Collecting static files..."
    python manage.py collectstatic --noinput
    ;;
esac

echo "Starting server... $(date '+%Y-%m-%d %H:%M:%S')"

WORKERS="${GUNICORN_WORKERS:-3}"

case "$(echo "$JANEWAY_HOT_RELOAD" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes)
    echo "#############################"
    echo "Running in HOT_RELOAD mode..."
    echo "#############################"
    exec python manage.py runserver 0.0.0.0:8000
    ;;
  *)
    echo "#############################"
    echo "Running in PRODUCTION mode"
    echo "Workers: $WORKERS"
    echo "#############################"
    exec gunicorn core.wsgi:application \
      --bind 0.0.0.0:8000 \
      --workers "$WORKERS" \
      --timeout 60 \
      --graceful-timeout 20 \
      --keep-alive 2 \
      --max-requests 500 \
      --max-requests-jitter 50 \
      --access-logfile - \
      --error-logfile -
    ;;
esac
