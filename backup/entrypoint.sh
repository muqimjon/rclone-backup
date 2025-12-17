#!/usr/bin/env bash
set -euo pipefail

readonly STATE_FILE="${BACKUP_DIR}/.backup_state"
readonly CRON_FILE=/etc/cron.d/dynamic-cron
readonly LOG_FILE=/var/log/cron.log

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

cron_to_minutes() {
    EXPR="$1"
    
    if [[ "$EXPR" =~ ^\*/([0-9]+)[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+\* ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$EXPR" == "@hourly" ]]; then
        echo "60"
    elif [[ "$EXPR" == "@daily" ]]; then
        echo "1440"
    elif [[ "$EXPR" =~ ^[0-9]+[[:space:]]+\*/([0-9]+) ]]; then
        echo $((${BASH_REMATCH[1]} * 60))
    else
        echo "1440"
    fi
}

check_missed_tasks() {
    CURRENT=$(date +%s)
    BACKUP_INTERVAL=$(($(cron_to_minutes "${CRON_BACKUP_SCHEDULE}") * 60))
    
    LAST_BACKUP=0
    LAST_UPLOAD=0
    
    if [ -f "${STATE_FILE}" ]; then
        source "${STATE_FILE}" 2>/dev/null || true
        LAST_BACKUP=${LAST_BACKUP:-0}
        LAST_UPLOAD=${LAST_UPLOAD:-0}
    fi
    
    log "=========================================="
    log "🔍 Vazifalar tekshirilmoqda..."
    
    # Backup tekshirish
    if [ $LAST_BACKUP -eq 0 ]; then
        log "⚡ Birinchi ishga tushirish - Backup yaratilmoqda..."
        /usr/local/bin/backup.sh
    else
        ELAPSED=$((CURRENT - LAST_BACKUP))
        DUE=$((LAST_BACKUP + BACKUP_INTERVAL))
        
        log "📊 Oxirgi backup: $(date -d @${LAST_BACKUP} +'%Y-%m-%d %H:%M:%S')"
        log "📊 O'tgan: $((ELAPSED / 60)) daq, Interval: $((BACKUP_INTERVAL / 60)) daq"
        
        if [ $CURRENT -ge $DUE ]; then
            log "⚡ Backup kechikkan! Darhol boshlanadi..."
            /usr/local/bin/backup.sh
        else
            log "✅ Backup o'z vaqtida"
        fi
    fi
    
    # Upload tekshirish (faqat alohida CRON_UPLOAD_SCHEDULE bo'lsa)
    if [ -n "${CRON_UPLOAD_SCHEDULE:-}" ]; then
        UPLOAD_INTERVAL=$(($(cron_to_minutes "${CRON_UPLOAD_SCHEDULE}") * 60))
        
        if [ $LAST_UPLOAD -eq 0 ]; then
            log "⚡ Upload boshlandi..."
            /usr/local/bin/upload.sh
        else
            ELAPSED=$((CURRENT - LAST_UPLOAD))
            DUE=$((LAST_UPLOAD + UPLOAD_INTERVAL))
            
            if [ $CURRENT -ge $DUE ]; then
                log "⚡ Upload kechikkan! Darhol boshlanadi..."
                /usr/local/bin/upload.sh
            fi
        fi
    fi
    
    # Cleanup tekshirish (faqat alohida CRON_CLEANUP_SCHEDULE bo'lsa)
    if [ -n "${CRON_CLEANUP_SCHEDULE:-}" ]; then
        log "⚡ Cleanup boshlandi..."
        /usr/local/bin/cleanup.sh
    fi
    
    log "=========================================="
}

setup_rclone() {
    export RCLONE_CONFIG="${RCLONE_CONFIG:-/tmp/rclone.conf}"
    
    if [ -f "$RCLONE_CONFIG" ]; then
        log "✅ Rclone: Volume ($RCLONE_CONFIG)"
    elif [ -n "${RCLONE_CONFIG_CONTENT:-}" ]; then
        mkdir -p "$(dirname "$RCLONE_CONFIG")"
        echo "$RCLONE_CONFIG_CONTENT" > "$RCLONE_CONFIG"
        chmod 600 "$RCLONE_CONFIG"
        log "✅ Rclone: ENV"
    else
        log "⚠️ Rclone yo'q"
    fi
}

setup_cron() {
    export CRON_BACKUP_SCHEDULE="${CRON_BACKUP_SCHEDULE:-0 0 * * *}"
    export CRON_UPLOAD_SCHEDULE="${CRON_UPLOAD_SCHEDULE:-}"
    export CRON_CLEANUP_SCHEDULE="${CRON_CLEANUP_SCHEDULE:-}"
    
    log "📝 Cron yaratilmoqda..."
    
    mkdir -p "$(dirname "$CRON_FILE")"
    
    cat > "$CRON_FILE" << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin

EOF
    
    cat >> "$CRON_FILE" << EOF
PROJECT_NAME='${PROJECT_NAME}'
PGHOST='${PGHOST}'
PGPORT='${PGPORT}'
PGUSER='${PGUSER}'
PGPASSWORD='${PGPASSWORD}'
PGDATABASE='${PGDATABASE}'
BACKUP_DIR='${BACKUP_DIR}'
RCLONE_CONFIG='${RCLONE_CONFIG}'
RCLONE_CONFIG_DIR='${RCLONE_CONFIG_DIR:-/tmp/rclone}'
RCLONE_REMOTE='${RCLONE_REMOTE}'
RCLONE_PATH='${RCLONE_PATH}'
COMPRESSION_LEVEL='${COMPRESSION_LEVEL}'
TZ='${TZ}'
BACKUP_PASSWORD='${BACKUP_PASSWORD:-}'
MIN_LOCAL_BACKUPS='${MIN_LOCAL_BACKUPS:-0}'
MAX_LOCAL_BACKUPS='${MAX_LOCAL_BACKUPS:-100}'
CRON_UPLOAD_SCHEDULE='${CRON_UPLOAD_SCHEDULE}'
CRON_CLEANUP_SCHEDULE='${CRON_CLEANUP_SCHEDULE}'

EOF
    
    # Backup cron (doim kerak)
    echo "${CRON_BACKUP_SCHEDULE} /usr/local/bin/backup.sh >> ${LOG_FILE} 2>&1" >> "$CRON_FILE"
    log "✅ Backup: ${CRON_BACKUP_SCHEDULE}"
    
    # Upload cron (faqat alohida vaqt berilgan bo'lsa)
    if [ -n "${CRON_UPLOAD_SCHEDULE}" ]; then
        echo "${CRON_UPLOAD_SCHEDULE} /usr/local/bin/upload.sh >> ${LOG_FILE} 2>&1" >> "$CRON_FILE"
        log "✅ Upload: ${CRON_UPLOAD_SCHEDULE} (mustaqil)"
    else
        log "ℹ️ Upload backup bilan birga ishlaydi"
    fi
    
    # Cleanup cron (faqat alohida vaqt berilgan bo'lsa)
    if [ -n "${CRON_CLEANUP_SCHEDULE}" ]; then
        echo "${CRON_CLEANUP_SCHEDULE} /usr/local/bin/cleanup.sh >> ${LOG_FILE} 2>&1" >> "$CRON_FILE"
        log "✅ Cleanup: ${CRON_CLEANUP_SCHEDULE} (mustaqil)"
    else
        log "ℹ️ Cleanup upload bilan birga ishlaydi"
    fi
    
    chmod 0644 "$CRON_FILE"
    crontab "$CRON_FILE"
    
    log "✅ Cron yuklandi"
}

log "=========================================="
log "🚀 PostgreSQL Backup Service"
log "=========================================="

setup_rclone
check_missed_tasks
setup_cron

touch "${LOG_FILE}"

log "🟢 Cron daemon ishga tushirilmoqda..."
log "=========================================="

exec cron -f -L 15