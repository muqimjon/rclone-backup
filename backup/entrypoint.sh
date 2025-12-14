#!/usr/bin/env bash
# Xavfsizlik uchun skriptni qat'iy rejimda ishga tushirish
set -euo pipefail

# Backup jadvalini o'rnatish (agar ENV da berilmagan bo'lsa, default qiymat berish)
export CRON_BACKUP_SCHEDULE="${CRON_BACKUP_SCHEDULE:-0 0 * * *}" 

# Cleanup jadvalini o'rnatish (agar berilmagan bo'lsa, Backup jadvalini qabul qiladi)
if [ -z "${CRON_CLEANUP_SCHEDULE:-}" ]; then
    export CRON_CLEANUP_SCHEDULE="${CRON_BACKUP_SCHEDULE}"
else
    export CRON_CLEANUP_SCHEDULE="${CRON_CLEANUP_SCHEDULE}"
fi

# Rclone konfiguratsiya faylini yaratish va ruxsatlarni sozlash
export RCLONE_CONFIG="${RCLONE_CONFIG:-/tmp/rclone.conf}"
if [ -n "${RCLONE_CONFIG_CONTENT:-}" ]; then
    mkdir -p "$(dirname "$RCLONE_CONFIG")"
    echo "$RCLONE_CONFIG_CONTENT" > "$RCLONE_CONFIG"
    chmod 600 "$RCLONE_CONFIG"
    echo "✅ Rclone konfiguratsiyasi yaratildi."
fi

# Dinamik Cron faylining manzilini belgilash
CRON_FILE=/etc/cron.d/dynamic-cron
mkdir -p "$(dirname "$CRON_FILE")"

# --- 2. Dinamik Crontab Faylini Yaratish va ENV O'rnatish ---
echo "--- 📝 Dinamik Cron Fayl Yaratilmoqda ---"

# Shell va PATH o'rnatish
echo "SHELL=/bin/bash" > "$CRON_FILE"
echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "$CRON_FILE"


echo "# ENV O'ZGARUVCHILARI" >> "$CRON_FILE" # Cron muhiti uchun SHELL va PATH ni o'rnatish
# MUHIM: Cron muhitiga Docker Compose'dan o'tgan barcha ENV o'zgaruvchilarini kiritish
echo "PROJECT_NAME='${PROJECT_NAME}'" >> "$CRON_FILE"
echo "PGHOST='${PGHOST}'" >> "$CRON_FILE"
echo "PGPORT='${PGPORT}'" >> "$CRON_FILE"
echo "PGUSER='${PGUSER}'" >> "$CRON_FILE"
echo "PGPASSWORD='${PGPASSWORD}'" >> "$CRON_FILE"
echo "PGDATABASE='${PGDATABASE}'" >> "$CRON_FILE"
echo "BACKUP_DIR='${BACKUP_DIR}'" >> "$CRON_FILE"
echo "RCLONE_CONFIG='${RCLONE_CONFIG}'" >> "$CRON_FILE"
echo "RCLONE_REMOTE='${RCLONE_REMOTE}'" >> "$CRON_FILE"
echo "RCLONE_PATH='${RCLONE_PATH}'" >> "$CRON_FILE"
echo "COMPRESSION_LEVEL='${COMPRESSION_LEVEL}'" >> "$CRON_FILE"
echo "TZ='${TZ}'" >> "$CRON_FILE"
echo "BACKUP_INTERVAL_SEC='${BACKUP_INTERVAL_SEC:-}'" >> "$CRON_FILE"
echo "CLEANUP_INTERVAL_SEC='${CLEANUP_INTERVAL_SEC:-}'" >> "$CRON_FILE"

# 3. Asosiy Backup Jadvalini Cron ga qo'shish (Cron log fayliga yo'naltirilgan)
echo "${CRON_BACKUP_SCHEDULE} root /bin/sh -c '/bin/bash /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1'" >> "$CRON_FILE"

# 4. Cleanup Jadvalini Qo'shish (Faqatgina backup jadvali bilan farqli bo'lsa)
if [ "$CRON_CLEANUP_SCHEDULE" != "$CRON_BACKUP_SCHEDULE" ]; then
    echo "Qoldiq tozalash alohida jadvalda ishlatilmoqda: ${CRON_CLEANUP_SCHEDULE}"
    echo "${CRON_CLEANUP_SCHEDULE} root /usr/local/bin/cleanup.sh >> /var/log/cron.log 2>&1" >> "$CRON_FILE"
else
    echo "Cleanup jadvali backup bilan bir xil. Alohida cleanup cron qo'shilmadi."
fi

# Cron jadvali fayliga ruxsatlarni o'rnatib, tizimga yuklash
chmod 0644 "$CRON_FILE"
crontab "$CRON_FILE"

# Cron servisni Boshlash. Konteynerni jonli tutish uchun foregroundda ishga tushirish
echo "--- 🟢 Cron Job Boshlandi ---"
exec cron -f