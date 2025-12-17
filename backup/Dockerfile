FROM debian:stable-slim

ARG PG_VERSION=latest
ENV PG_VERSION=${PG_VERSION}

RUN apt-get update && \
    if [ "$PG_VERSION" = "latest" ]; then \
        apt-get install -y postgresql-client rclone bash tzdata ca-certificates curl cron zip && \
        apt-get clean; \
    else \
        apt-get install -y postgresql-client-${PG_VERSION} rclone bash tzdata ca-certificates curl cron zip && \
        apt-get clean; \
    fi && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/wait-for-it.sh \
    https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it.sh

ENV PROJECT_NAME=your-project-name \
    PGHOST=localhost \
    PGPORT=5432 \
    PGUSER=postgres \
    PGPASSWORD=your-password \
    PGDATABASE=your-database-name \
    BACKUP_DIR=/backup \
    RCLONE_CONFIG=/tmp/rclone.conf \
    RCLONE_REMOTE=your-remote-name \
    RCLONE_PATH=your-backup-path \
    COMPRESSION_LEVEL=9 \
    MIN_LOCAL_BACKUPS=0 \
    MAX_LOCAL_BACKUPS=100 \
    TZ=UTC

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /usr/local/bin/backup.sh
COPY upload.sh /usr/local/bin/upload.sh
COPY cleanup.sh /usr/local/bin/cleanup.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
             /usr/local/bin/backup.sh \
             /usr/local/bin/upload.sh \
             /usr/local/bin/cleanup.sh

HEALTHCHECK --interval=5m --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep cron > /dev/null || exit 1