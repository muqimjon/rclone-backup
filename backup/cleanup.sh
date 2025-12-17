#!/usr/bin/env bash
set -euo pipefail

readonly BACKUP_DIR="${BACKUP_DIR:-/backup}"
readonly STATE_FILE="${BACKUP_DIR}/.backup_state"
readonly MIN_LOCAL_BACKUPS="${MIN_LOCAL_BACKUPS:-0}"
readonly MAX_LOCAL_BACKUPS="${MAX_LOCAL_BACKUPS:-100}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

cleanup_old_files() {
    log "=========================================="
    log "🗑️ Fayllarni tozalash boshlandi..."
    
    FILE_COUNT=$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.zip" 2>/dev/null | wc -l)
    
    if [ "$FILE_COUNT" -eq 0 ]; then
        log "ℹ️ Tozalanadigan fayllar yo'q"
        log "=========================================="
        return 0
    fi
    
    log "📊 Lokal fayllar: ${FILE_COUNT} ta (min: ${MIN_LOCAL_BACKUPS}, max: ${MAX_LOCAL_BACKUPS})"
    
    # Oxirgi upload vaqtini olish
    LAST_UPLOAD=0
    
    if [ -f "${STATE_FILE}" ]; then
        source "${STATE_FILE}" 2>/dev/null || true
        LAST_UPLOAD=${LAST_UPLOAD:-0}
    fi
    
    if [ $LAST_UPLOAD -eq 0 ]; then
        log "⚠️ Hech narsa cloudga yuklanmagan - fayllar saqlanadi"
        log "=========================================="
        return 0
    fi
    
    log "📊 Oxirgi yuklash: $(date -d @${LAST_UPLOAD} +'%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r ${LAST_UPLOAD} +'%Y-%m-%d %H:%M:%S')"
    
    DELETED=0
    
    # MAX_LOCAL_BACKUPS chegarasini tekshirish
    if [ "$FILE_COUNT" -gt "$MAX_LOCAL_BACKUPS" ]; then
        TO_DELETE=$((FILE_COUNT - MAX_LOCAL_BACKUPS))
        log "🗑️ MAX chegaradan oshdi! ${TO_DELETE} ta eski fayl o'chiriladi..."
        
        while IFS= read -r FILE; do
            FILENAME=$(basename "$FILE")
            log "🗑️ O'chirildi: ${FILENAME}"
            rm -f "$FILE"
            DELETED=$((DELETED + 1))
        done < <(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.zip" 2>/dev/null | sort | head -n "$TO_DELETE")
        
    # MIN_LOCAL_BACKUPS dan ortiq fayllar bormi tekshirish
    elif [ "$FILE_COUNT" -gt "$MIN_LOCAL_BACKUPS" ]; then
        TO_DELETE=$((FILE_COUNT - MIN_LOCAL_BACKUPS))
        log "🗑️ ${TO_DELETE} ta ortiqcha fayl o'chiriladi (min ${MIN_LOCAL_BACKUPS} saqlanadi)..."
        
        while IFS= read -r FILE; do
            FILENAME=$(basename "$FILE")
            FILE_TIMESTAMP=$(stat -c%Y "$FILE" 2>/dev/null || stat -f%m "$FILE" 2>/dev/null || echo "0")
            
            # Faqat cloudga yuklangan fayllarni o'chirish
            if [ "$FILE_TIMESTAMP" -le "$LAST_UPLOAD" ]; then
                log "🗑️ O'chirildi: ${FILENAME}"
                rm -f "$FILE"
                DELETED=$((DELETED + 1))
            else
                log "⏭️ Hali yuklanmagan: ${FILENAME}"
            fi
        done < <(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.zip" 2>/dev/null | sort | head -n "$TO_DELETE")
    else
        log "✅ Tozalash kerak emas (fayllar: ${FILE_COUNT}, min: ${MIN_LOCAL_BACKUPS})"
    fi
    
    [ $DELETED -gt 0 ] && log "📊 O'chirildi: ${DELETED} ta fayl"
    
    log "✅ Tozalash tugadi"
    log "=========================================="
}

cleanup_old_files