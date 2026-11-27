# ---- Builder stage: install Python deps with the full toolchain, then discard it ----
FROM python:3.10-slim-bookworm AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Build toolchain + headers to compile wheels for lxml / Pillow / psycopg2 /
# libsass, plus git for the editable VCS requirements (-e git+... in
# requirements.txt). None of this ships in the final image.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        libxml2-dev \
        libxslt1-dev \
        libjpeg-dev \
        zlib1g-dev \
        libffi-dev \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Janeway's Python deps into the default prefix (/usr/local). Editable
# VCS checkouts (-e git+...) are placed under /usr/local/src so they can be
# carried into the final image at the exact path their .egg-link/.pth entries
# reference. gunicorn is added here; psycopg2-binary is already pinned in
# requirements.txt (bundles its own libpq — no libpq-dev/libpq5 needed).
COPY janeway/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --src /usr/local/src -r /tmp/requirements.txt gunicorn \
    && rm /tmp/requirements.txt

# ---- Final stage: slim runtime image, no build toolchain ----
FROM python:3.10-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Runtime-only shared libs:
#   libmagic1              -> python-magic (dlopen'd at runtime, never bundled)
#   libxml2 / libxslt1.1   -> lxml (if the sdist rather than the wheel was built)
#   libjpeg62-turbo        -> Pillow
#   curl                   -> the container healthcheck in docker-compose.yaml
# psycopg2-binary bundles libpq, so libpq5/libpq-dev are intentionally absent.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libmagic1 \
        libxml2 \
        libxslt1.1 \
        libjpeg62-turbo \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Bring in installed site-packages, console scripts (gunicorn), and the editable
# VCS checkouts under /usr/local/src. Both stages share the identical base
# image, so overlaying /usr/local only adds the Python deps.
COPY --from=builder /usr/local /usr/local

# Non-root user (uid 1000 matches default host user for bind-mount perms)
RUN useradd -m -u 1000 -s /bin/bash appuser \
    && mkdir -p /app && chown -R appuser:appuser /app

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER appuser
WORKDIR /app

EXPOSE 8000
CMD ["/usr/local/bin/entrypoint.sh"]
