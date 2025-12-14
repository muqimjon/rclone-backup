#!/usr/bin/env bash
# Xavfsiz rejim: Xato yuz bersa yoki o'zgaruvchi topilmasa to'xtatadi.
set -euo pipefail

# --- Fayl nomini yaratish ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${PROJECT_NAME}_${PGDATABASE}_${TIMESTAMP}.sql.gz"
LOCAL_FILE_PATH="${BACKUP_DIR}/${FILENAME}"

echo ">>> Backup boshlandi: ${TIMESTAMP} (PG Dump)"

# 1. PostgreSQL dump olish va Gzip yordamida siqish
if pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -Fp | gzip -${COMPRESSION_LEVEL} > "${LOCAL_FILE_PATH}"; then
    echo "✅ Dump va siqish muvaffaqiyatli: ${FILENAME}"
else
    echo "❌ Xatolik: pg_dump/DB ulanishi muvaffaqiyatsiz."
    exit 1
fi

# PGPASSWORD ni muhitdan o'chirish (xavfsizlik uchun)
unset PGPASSWORD

# 2. Cleanup faylini ishga tushirish (Yuklash va lokal tozalash)
echo "--- ♻️ Yuklash va Qoldiq tozalash boshlandi ---"
/usr/local/bin/cleanup.sh

echo "<<< Backup jarayoni tugadi: ${TIMESTAMP}"
echo "--------------------------------------------------------"