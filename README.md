# PostgreSQL Backup Service

🚀 Avtomatik PostgreSQL backup servisi Google Drive (yoki boshqa cloud) bilan integratsiyalangan.

## ✨ Asosiy Xususiyatlar

- ✅ **Avtomatik Backup Recovery**: Agar server o'chiq bo'lsa, qayta ishga tushganda o'tkazib yuborilgan backuplarni avtomatik bajaradi
- ✅ **Flexible Scheduling**: Cron format bilan istalgan jadval
- ✅ **Password Protection**: Backup fayllarni parol bilan shifrlash
- ✅ **Cloud Upload**: Rclone orqali 40+ cloud provayderga yuklash
- ✅ **Smart Cleanup**: Eski lokal fayllarni avtomatik tozalash
- ✅ **State Tracking**: Har bir operatsiya vaqti saqlanadi
- ✅ **Zero Data Loss**: Tarmoq uzilsa, fayllar lokal saqlanadi

## 📋 Talablar

- Docker & Docker Compose
- PostgreSQL database
- Rclone konfiguratsiyasi (Google Drive yoki boshqa)

## 🚀 Ishga Tushirish

### 1. Rclone Konfiguratsiyasini Sozlash

```bash
# Rclone config yaratish
rclone config

# Yoki mavjud configni ko'chirish
cp ~/.config/rclone/rclone.conf ./backup/rclone.conf
```

### 2. Docker Compose Sozlamalarini O'zgartirish

`docker-compose.yml` faylida quyidagilarni sozlang:

```yaml
environment:
  # Database ma'lumotlari
  PGHOST: postgres
  PGUSER: postgres
  PGPASSWORD: your-password
  PGDATABASE: your-database
  
  # Backup sozlamalari
  BACKUP_PASSWORD: your-backup-password  # Ixtiyoriy
  MAX_LOCAL_BACKUPS: 5
  
  # Rclone sozlamalari
  RCLONE_REMOTE: gdrive
  RCLONE_PATH: cloud/backups/your-project
  
  # Jadvallar (Cron format)
  CRON_BACKUP_SCHEDULE: "0 2 * * *"  # Har kuni soat 2da
```

### 3. Ishga Tushirish

```bash
docker-compose up -d backup
```

## 🎯 Qanday Ishlaydi?

### Backup Jarayoni
```
1. BACKUP.SH ishga tushadi
   ├─ PostgreSQL dump yaratadi
   ├─ ZIP siqadi (parol bilan yoki parolsiz)
   ├─ /backup papkaga saqlaydi
   └─ CLEANUP.SH ni chaqiradi

2. CLEANUP.SH ishga tushadi
   ├─ Barcha .zip fayllarni topadi
   ├─ Har birini cloudga yuklaydi
   ├─ Muvaffaqiyatli yuklangan faylni o'chiradi
   ├─ Agar cloud ishlamasa, fayl saqlanadi
   └─ MAX_LOCAL_BACKUPS dan ortiq bo'lsa, eskisini o'chiradi
```

### CRON_CLEANUP_SCHEDULE nima uchun kerak?

**2 xil rejim:**

1. **Oddiy rejim (CRON_CLEANUP_SCHEDULE yo'q):**
   - Har backup qilinganda avtomatik cleanup qilinadi
   - Misol: `CRON_BACKUP_SCHEDULE: "*/10 * * * *"` (10 daqiqada)

2. **Alohida rejim (CRON_CLEANUP_SCHEDULE bor):**
   - Backup va cleanup alohida vaqtda ishlaydi
   - Misol: 
     - `CRON_BACKUP_SCHEDULE: "0 2 * * *"` (soat 2da backup)
     - `CRON_CLEANUP_SCHEDULE: "*/5 * * * *"` (5 daqiqada qolgan fayllarni yuklash)
   - **Foyda:** Internet uzilsa, 5 daqiqada qayta urinadi

### MAX_LOCAL_BACKUPS qanday ishlaydi?

**Misol:** `MAX_LOCAL_BACKUPS: 5`

```
/backup papkada:
├─ file1.zip  ← Eng eski
├─ file2.zip
├─ file3.zip
├─ file4.zip
├─ file5.zip
└─ file6.zip  ← Yangi

Natija: file1.zip o'chiriladi
```

**MUHIM:** Fayllar faqat **cloud yuklangandan keyin** o'chiriladi!

Internet yo'q bo'lsa:
- Fayllar saqlanadi
- Yuklashga harakat qilinadi
- MAX_LOCAL_BACKUPS dan oshganda, **eng eskisi o'chiriladi**

## 📅 Cron Jadval Misollari

```bash
# Har 10 daqiqada
CRON_BACKUP_SCHEDULE: "*/10 * * * *"

# Har soatda
CRON_BACKUP_SCHEDULE: "0 * * * *"

# Har kuni soat 2:30da
CRON_BACKUP_SCHEDULE: "30 2 * * *"

# Har dushanba soat 3da
CRON_BACKUP_SCHEDULE: "0 3 * * 1"

# Har oyning 1-sanasida
CRON_BACKUP_SCHEDULE: "0 0 1 * *"
```

## 🔧 Muhim Sozlamalar

### MAX_LOCAL_BACKUPS
Lokal saqlash uchun maksimal backup fayllar soni. Eski fayllar avtomatik o'chiriladi.

```yaml
MAX_LOCAL_BACKUPS: 5  # Oxirgi 5 ta backup saqlanadi
```

### BACKUP_PASSWORD
Backup fayllarni ZIP parol bilan shifrlash (ixtiyoriy):

```yaml
BACKUP_PASSWORD: "your-secure-password"
```

Agar bo'sh qoldirilsa, shifrlashsiz oddiy ZIP yaratiladi.

### COMPRESSION_LEVEL
ZIP siqish darajasi (0-9):

```yaml
COMPRESSION_LEVEL: 9  # Maksimal siqish
```

## 🔄 Missed Task Recovery Qanday Ishlaydi

Dastur ishga tushganda quyidagilarni tekshiradi:

1. **State File** (`/backup/.backup_state`) o'qiladi
2. **Oxirgi backup vaqti** va **belgilangan interval** solishtiriladi
3. **Agar vaqt o'tib ketgan bo'lsa**, darhol backup bajariladi
4. **Yangi vaqt** state file ga saqlanadi
5. **Keyingi jadvalga** qaytadi

### Misol

```
Jadval: Har 10 soatda
Oxirgi backup: 2024-01-01 05:00
Server o'chgan: 2024-01-01 08:00
Server yongan: 2024-01-01 16:00

✅ 11 soat o'tgan (10 soatdan ortiq)
✅ Darhol backup bajariladi
✅ Keyingi backup: 2024-01-02 02:00
```

## 📊 Loglarni Ko'rish

```bash
# Barcha loglar
docker logs -f backup

# Oxirgi 100 qator
docker logs --tail 100 backup

# Faqat backup loglar
docker exec backup tail -f /var/log/cron.log
```

## 🛠️ Troubleshooting

### "root: command not found" xatosi

Bu xato `/etc/cron.d/` formatida cron ishlatganda paydo bo'ladi. Hal qilindi - `root` so'zi olib tashlangan.

### Rclone "device or resource busy" xatosi

Rclone read-only config faylni o'zgartirmoqchi bo'ladi. Hal qilish:

```yaml
environment:
  RCLONE_CONFIG_DIR: /tmp/rclone  # Temp dir uchun
```

Bu endi avtomatik hal qilingan.

### Backup ishlamayapti

```bash
# Containerning holatini tekshirish
docker ps | grep backup

# Cron jadvalini tekshirish
docker exec backup crontab -l

# State faylni tekshirish
docker exec backup cat /backup/.backup_state
```

### Rclone ulanmayapti

```bash
# Rclone konfiguratsiyasini tekshirish
docker exec backup rclone config show

# Test upload
docker exec backup rclone ls gdrive:
```

### Manual backup

```bash
# Qo'lda backup bajarish
docker exec backup /usr/local/bin/backup.sh
```

## 📁 Fayl Tuzilishi

```
.
├── backup/
│   ├── Dockerfile
│   ├── entrypoint.sh      # Ishga tushirish va state check
│   ├── backup.sh          # Asosiy backup script
│   ├── cleanup.sh         # Upload va tozalash
│   └── rclone.conf        # Rclone konfiguratsiyasi
├── data/
│   ├── backup/            # Lokal backup fayllar
│   │   └── .backup_state  # Holat fayli (avtomatik yaratiladi)
│   └── pgdata/            # PostgreSQL data
└── docker-compose.yml
```

## 🔐 Xavfsizlik

- ✅ Parollar environment variables orqali
- ✅ Rclone config read-only mode
- ✅ PGPASSWORD runtime da o'chiriladi
- ✅ Backup fayllar ixtiyoriy parol bilan

## 📝 Lisenziya

MIT License

## 🤝 Yordam

Muammolar yoki savollarga GitHub Issues orqali murojaat qiling.