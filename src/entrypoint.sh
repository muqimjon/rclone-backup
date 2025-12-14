set -euo pipefail

# Timezone sozlash
if [ -n "${TZ}" ]; then
  echo "Setting timezone to ${TZ}"
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

# Cron jadvalini yozib qo'yamiz
CRON_LINE="${CRON_SCHEDULE} /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1"
echo "${CRON_LINE}" > /etc/crontabs/root

mkdir -p "${BACKUP_DIR}"
mkdir -p "$(dirname "${RCLONE_CONFIG}")"

echo "Starting crond with schedule: ${CRON_SCHEDULE} (TZ=${TZ})"
crond -f -l 8