FROM python:3.10-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# System deps: build toolchain (purged later), runtime libs for lxml / Pillow / psycopg2 / file-type detection
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        libxml2-dev \
        libxslt1-dev \
        libjpeg-dev \
        zlib1g-dev \
        libpq-dev \
        libffi-dev \
        libssl-dev \
        libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Install Janeway's Python deps from the source tree cloned on the host
# (backend/ build context → janeway/ is the BirkbeckCTP/janeway clone).
COPY janeway/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt \
    && pip install gunicorn psycopg2-binary \
    && rm /tmp/requirements.txt

# Strip build toolchain, keep only runtime libs
RUN apt-get purge -y --auto-remove build-essential libpq-dev \
    && apt-get update && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Non-root user (uid 1000 matches default host user for bind-mount perms)
RUN useradd -m -u 1000 -s /bin/bash appuser \
    && mkdir -p /app && chown -R appuser:appuser /app

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER appuser
WORKDIR /app

EXPOSE 8000
CMD ["/usr/local/bin/entrypoint.sh"]
