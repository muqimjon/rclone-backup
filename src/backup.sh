set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${PROJECT_NAME}_${PGDATABASE}_${TIMESTAMP}.sql.gz"
LOCAL_FILE_PATH="${BACKUP_DIR}/${FILENAME}"

echo "=== Backup start: ${TIMESTAMP} (TZ=${TZ}) ==="
echo "Dumping Postgres database ${PGDATABASE} from ${PGHOST}:${PGPORT}..."

PGPASSFILE=$(mktemp)
echo "${PGHOST}:${PGPORT}:${PGDATABASE}:${PGUSER}:${PGPASSWORD}" > "$PGPASSFILE"
chmod 600 "$PGPASSFILE"
export PGPASSFILE

pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -Fp | gzip -${COMPRESSION_LEVEL} > "${LOCAL_FILE_PATH}"

rm -f "$PGPASSFILE"

echo "✅ Backup created: ${LOCAL_FILE_PATH}"

if [ -n "${RCLONE_REMOTE}" ] && [ -n "${RCLONE_PATH}" ]; then
  echo "☁️ Uploading to ${RCLONE_REMOTE}:${RCLONE_PATH} ..."
  rclone --config "${RCLONE_CONFIG}" copy "${LOCAL_FILE_PATH}" "${RCLONE_REMOTE}:${RCLONE_PATH}" --checkers 8
  echo "✅ Upload finished."
else
  echo "⚠️ RCLONE_REMOTE or RCLONE_PATH not set; skipping cloud upload."
fi

echo "=== Backup end: ${TIMESTAMP} ==="
