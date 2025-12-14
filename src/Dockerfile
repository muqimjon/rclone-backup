FROM alpine:3.20

# Kerakli paketlar: Postgres client + rclone + bash + tzdata
# Posgres client - ma'lumotlarni zaxiralash uchun
# rclone - zaxiralarni bulutga yuklash uchun
# bash - skriptlarni bajarish uchun
# tzdata - vaqt zonasi ma'lumotlari

RUN apk add --no-cache postgresql-client rclone bash tzdata ca-certificates \
    && update-ca-certificates

# Default ENV qiymatlar
ENV PROJECT_NAME=your-project-name
ENV PGHOST=localhost
ENV PGPORT=5432
ENV PGUSER=postgres
ENV PGPASSWORD=your-password
ENV PGDATABASE=your-database-name
ENV BACKUP_DIR=/backup
ENV RCLONE_CONFIG=/root/.config/rclone/rclone.conf
ENV RCLONE_REMOTE=your-remote-name
ENV RCLONE_PATH=your-backup-path
ENV CRON_SCHEDULE="0 0 * * *"
ENV COMPRESSION_LEVEL=9
ENV TZ=UTC

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /usr/local/bin/backup.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/backup.sh

CMD ["/usr/local/bin/entrypoint.sh"]
