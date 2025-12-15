FROM debian:stable-slim

# Build-time argument
ARG PG_VERSION=latest
ENV PG_VERSION=${PG_VERSION}

# Postgres client, rclone, bash, tzdata, ca-certificates, curl, cron VA ZIP ni o'rnatish
RUN apt-get update && \
    if [ "$PG_VERSION" = "latest" ]; then \
        apt-get install -y postgresql-client rclone bash tzdata ca-certificates curl cron zip; \
    else \
        apt-get install -y postgresql-client-${PG_VERSION} rclone bash tzdata ca-certificates curl cron zip; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# wait-for-it.sh ni yuklash va ijro etish huquqini berish
RUN curl -s -o /usr/local/bin/wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it.sh

# Default env (run-time da override qilinadi)
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
    TZ=UTC

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /usr/local/bin/backup.sh
COPY cleanup.sh /usr/local/bin/cleanup.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/backup.sh /usr/local/bin/cleanup.sh

# CMD buyrug'i docker-compose.yml da bekor qilingan va command orqali wait-for-it.sh beriladi
# CMD ["/usr/local/bin/entrypoint.sh"]