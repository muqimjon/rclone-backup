#!/usr/bin/env bash
set -euo pipefail

readonly BACKUP_DIR="${BACKUP_DIR:-/backup}"
readonly RCLONE_CONFIG="${RCLONE_CONFIG:-/tmp/rclone.conf}"
readonly RCLONE_REMOTE="${RCLONE_REMOTE:-}"
readonly RCLONE_PATH="${RCLONE_PATH:-}"
readonly STATE_FILE="${BACKUP_DIR}/.backup_state"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

upload_files() {
    if [ -z "${RCLONE_REMOTE}" ] || [ -z "${RCLONE_PATH}" ]; then
        log "⚠️ Rclone sozlanmagan - yuklash o'tkazib yuborildi"
        return 0
    fi
    
    log "=========================================="
    log "☁️ Cloudga yuklash boshlandi..."
    
    # Yuklanadigan fayllar bormi tekshirish
    if ! find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.zip" -print -quit 2>/dev/null | grep -q .; then
        log "ℹ️ Yuklanadigan fayllar yo'q"
        log "=========================================="
        return 0
    fi
    
    LAST_UPLOAD=0
    
    if [ -f "${STATE_FILE}" ]; then
        source "${STATE_FILE}" 2>/dev/null || true
        LAST_UPLOAD=${LAST_UPLOAD:-0}
    fi
    
    log "📊 Oxirgi yuklash: $(date -d @${LAST_UPLOAD} +'%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'Hech qachon')"
    
    UPLOADED=0
    FAILED=0
    TOTAL_SIZE=0
    
    # Fayllarni vaqt bo'yicha tartiblash va yuklash
    while IFS= read -r FILE; do
        FILENAME=$(basename "$FILE")
        FILE_TIMESTAMP=$(stat -c%Y "$FILE" 2>/dev/null || stat -f%m "$FILE" 2>/dev/null || echo "0")
        
        # Faqat oxirgi uploaddan keyin yaratilgan fayllarni yuklash
        if [ "$FILE_TIMESTAMP" -le "$LAST_UPLOAD" ]; then
            log "⏭️ Allaqachon yuklangan: ${FILENAME}"
            continue
        fi
        
        FILE_SIZE=$(stat -c%s "$FILE" 2>/dev/null || stat -f%z "$FILE" 2>/dev/null || echo "0")
        FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
        
        log "⬆️ Yuklanmoqda: ${FILENAME} (${FILE_SIZE_MB} MB)..."
        
        if rclone --config "${RCLONE_CONFIG}" --no-update-modtime \
            copy "$FILE" "${RCLONE_REMOTE}:${RCLONE_PATH}" \
            --checkers 2 --retries 2 --low-level-retries 3 --quiet 2>/dev/null; then
            
            log "✅ Yuklandi: ${FILENAME}"
            UPLOADED=$((UPLOADED + 1))
            TOTAL_SIZE=$((TOTAL_SIZE + FILE_SIZE))
        else
            log "❌ Yuklash xatosi: ${FILENAME}"
            FAILED=$((FAILED + 1))
        fi
    done < <(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.zip" 2>/dev/null | sort)
    
    if [ $UPLOADED -gt 0 ]; then
        TOTAL_SIZE_MB=$((TOTAL_SIZE / 1024 / 1024))
        log "📊 Jami yuklandi: ${UPLOADED} ta fayl (${TOTAL_SIZE_MB} MB)"
        
        # Upload vaqtini saqlash
        CURRENT_TIME=$(date +%s)
        if [ -f "${STATE_FILE}" ]; then
            sed -i '/^LAST_UPLOAD=/d' "${STATE_FILE}" 2>/dev/null || true
        fi
        echo "LAST_UPLOAD=${CURRENT_TIME}" >> "${STATE_FILE}"
        
        log "📝 Upload vaqti saqlandi: $(date -d @${CURRENT_TIME} +'%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r ${CURRENT_TIME} +'%Y-%m-%d %H:%M:%S')"
    fi
    
    [ $FAILED -gt 0 ] && log "⚠️ Xato: ${FAILED} ta fayl"
    
    log "✅ Yuklash tugadi"
    log "=========================================="
}

upload_files

# Agar CRON_CLEANUP_SCHEDULE bo'sh bo'lsa, darhol cleanup.sh ni chaqirish
if [ -z "${CRON_CLEANUP_SCHEDULE:-}" ]; then
    log "➡️ Cleanup boshlanyapti (upload bilan birga)..."
    /usr/local/bin/cleanup.sh
fi