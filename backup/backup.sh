#!/usr/bin/env bash
set -euo pipefail

# --- Fayl nomini yaratish ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SQL_FILENAME="${PROJECT_NAME}_${PGDATABASE}_${TIMESTAMP}.sql"
FILENAME="${PROJECT_NAME}_${PGDATABASE}_${TIMESTAMP}.zip"
LOCAL_FILE_PATH="${BACKUP_DIR}/${FILENAME}"

# Log xabarini parollash holatiga qarab chiqarish
if [ -n "${BACKUP_PASSWORD:-}" ]; then
    echo ">>> Backup boshlandi: ${TIMESTAMP} (PG Dump + Zip + Parollash)"
else
    echo ">>> Backup boshlandi: ${TIMESTAMP} (PG Dump + Zip)"
fi

# 1. PostgreSQL dump olish, siqish va shifrlash (agar parol berilgan bo'lsa)
if [ -n "${BACKUP_PASSWORD:-}" ]; then
    pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -Fp | zip -j -z -P "${BACKUP_PASSWORD}" "${LOCAL_FILE_PATH}" -n "${SQL_FILENAME}" -
    DUMP_STATUS=$?
else
    pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -Fp | zip -j -z "${LOCAL_FILE_PATH}" -n "${SQL_FILENAME}" -
    DUMP_STATUS=$?
fi

if [ $DUMP_STATUS -eq 0 ]; then
    echo "✅ Dump, siqish va $([ -n "${BACKUP_PASSWORD:-}" ] && echo "parollash" || echo "siqish") muvaffaqiyatli: ${FILENAME}"
else
    echo "❌ Xatolik: pg_dump/zip muvaffaqiyatsiz."
    exit 1
fi

# PGPASSWORD ni o'chirish (xavfsizlik uchun)
unset PGPASSWORD

# 2. Cleanup faylini ishga tushirish
echo "--- ♻️ Yuklash va Qoldiq tozalash boshlandi ---"
/usr/local/bin/cleanup.sh

echo "<<< Backup jarayoni tugadi: ${TIMESTAMP}"
echo "--------------------------------------------------------"