#!/usr/bin/env bash
set -euo pipefail

readonly STATE_FILE="${BACKUP_DIR}/.backup_state"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly ZIP_FILENAME="${PROJECT_NAME}_${PGDATABASE}_${TIMESTAMP}.zip"
readonly LOCAL_FILE_PATH="${BACKUP_DIR}/${ZIP_FILENAME}"

mkdir -p "${BACKUP_DIR}" 2>/dev/null || true

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error_exit() {
    log "❌ XATOLIK: $1" >&2
    exit "${2:-1}"
}

log "=========================================="
log "🔄 Backup boshlandi: ${ZIP_FILENAME}"

if [ -n "${BACKUP_PASSWORD:-}" ]; then
    log "🔐 Parol bilan shifrlash"
    pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -Fp \
        | zip -j -${COMPRESSION_LEVEL} -P "${BACKUP_PASSWORD}" -q "${LOCAL_FILE_PATH}" - || \
        error_exit "pg_dump/zip xatosi"
else
    log "📦 Oddiy siqish"
    pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -Fp \
        | zip -j -${COMPRESSION_LEVEL} -q "${LOCAL_FILE_PATH}" - || \
        error_exit "pg_dump/zip xatosi"
fi

unset PGPASSWORD 2>/dev/null || true

FILE_SIZE=$(stat -f%z "${LOCAL_FILE_PATH}" 2>/dev/null || stat -c%s "${LOCAL_FILE_PATH}" 2>/dev/null || echo "0")
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

log "✅ Yaratildi: ${ZIP_FILENAME} (${FILE_SIZE_MB} MB)"

CURRENT_TIME=$(date +%s)

# State faylni yangilash
if [ -f "${STATE_FILE}" ]; then
    sed -i '/^LAST_BACKUP=/d' "${STATE_FILE}" 2>/dev/null || true
fi
echo "LAST_BACKUP=${CURRENT_TIME}" >> "${STATE_FILE}"

log "📝 Vaqt saqlandi: $(date -d @${CURRENT_TIME} +'%Y-%m-%d %H:%M:%S')"
log "✅ Backup tugadi"
log "=========================================="

# Agar CRON_UPLOAD_SCHEDULE bo'sh bo'lsa, darhol upload.sh ni chaqirish
if [ -z "${CRON_UPLOAD_SCHEDULE:-}" ]; then
    log "➡️ Upload boshlanyapti (backup bilan birga)..."
    /usr/local/bin/upload.sh
fi