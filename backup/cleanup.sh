#!/usr/bin/env bash
set -euo pipefail

export BACKUP_DIR="${BACKUP_DIR:-/backup}"
export RCLONE_CONFIG="${RCLONE_CONFIG:-/root/.config/rclone/rclone.conf}"
export RCLONE_REMOTE="${RCLONE_REMOTE:-}"
export RCLONE_PATH="${RCLONE_PATH:-}"

# RCLONE konfiguratsiyasi mavjud bo'lsa va backup fayllari bo'lsa ishga tushirish
if [ -n "${RCLONE_REMOTE}" ] && [ -n "${RCLONE_PATH}" ]; then 
   # Backup papkasida .zip fayllari mavjudligini tekshirish (O'zgartirildi)
   if find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.zip" -print -quit 2>/dev/null | grep -q .; then
      
      echo "☁️ Qoldiq Fayllarni Yuklash boshlandi."
      
      # Har bir topilgan .zip faylini qayta yuklashga harakat qilish (O'zgartirildi)
      find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.zip" -print0 | while IFS= read -r -d $'\0' FILE_TO_UPLOAD; do
         FILENAME_ONLY=$(basename "$FILE_TO_UPLOAD")
         
         # rclone yordamida faylni uzoq serverga yuklash (network uzilsa keyingi sinovgacha qoladi)
         rclone --config "${RCLONE_CONFIG}" copy "$FILE_TO_UPLOAD" "${RCLONE_REMOTE}:${RCLONE_PATH}" --checkers 2 --retries 1 --low-level-retries 3
  
         # Yuklash muvaffaqiyatli bo'lsa, lokal faylni o'chirish
         if [ $? -eq 0 ]; then
            echo "✅ Lokal fayl yuklandi. O'chirildi: $FILENAME_ONLY"
            rm "$FILE_TO_UPLOAD"
         else
            echo "❌ Yuklash muvaffaqiyatsiz. Tarmoq yo'q. Keyingi sinovgacha saqlandi: $FILENAME_ONLY"
         fi
      done
      echo "--- 🟢 Qoldiq Yuklash Tugadi ---"
   fi
fi