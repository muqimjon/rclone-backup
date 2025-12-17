# PostgreSQL Backup Service 🚀

Avtomatik PostgreSQL backup xizmati - ma'lumotlaringizni xavfsiz saqlang va cloudga yuklang!

## 🎯 Nima Uchun Kerak?

- **Ma'lumotlarni yo'qotmaslik**: Database buzilsa yoki server ishlamay qolsa, backupdan tiklashingiz mumkin
- **Avtomatik jarayon**: Siz hech narsa qilmasangiz ham belgilangan vaqtda backup olinadi
- **Cloud saqlash**: Backuplar Google Drive yoki boshqa cloudga yuklanadi
- **Xavfsizlik**: Backup fayllar parol bilan shifrlanadi
- **Smart tizim**: Internet yo'q bo'lsa, lokal saqlab qo'yadi va keyinroq yuklaydi

---

## ✨ Asosiy Imkoniyatlar

| Xususiyat | Ta'rif |
|-----------|--------|
| 🔄 **3 ta mustaqil jarayon** | Backup → Upload → Cleanup (har biri alohida yoki birga ishlaydi) |
| ⏰ **Flexible jadval** | Har qanday vaqtni belgilashingiz mumkin (cron format) |
| 🔐 **Parol himoyasi** | ZIP fayllarni parol bilan shifrlash |
| ☁️ **Cloud upload** | 40+ cloud provayderga yuklash (Google Drive, Dropbox va h.k.) |
| 🗑️ **Smart tozalash** | Yuklangan eski fayllarni avtomatik o'chirish |
| 💾 **Offline saqlash** | Internet yo'q bo'lsa, lokal saqlaydi |
| 📊 **State tracking** | Har bir amal vaqti saqlanadi |

---

## 📋 Kerakli Narsalar

- Docker va Docker Compose
- PostgreSQL database
- Rclone konfiguratsiyasi (Google Drive yoki boshqa cloud uchun)

---

## 🚀 Ishga Tushirish

### 1️⃣ Rclone'ni Sozlash

Google Drive yoki boshqa cloudga ulanish uchun:

```bash
# Rclone config yaratish
rclone config

# Yoki mavjud configni nusxalash
cp ~/.config/rclone/rclone.conf ./backup/rclone.conf
```

**Google Drive uchun:**
- Remote name: `gdrive` (yoki o'zingiz tanlagan nom)
- Scope: `drive` (to'liq access)
- Service Account: Yo'q (shaxsiy account)

### 2️⃣ Docker Compose Sozlamalarini O'zgartirish

`docker-compose.yml` faylida o'zingizning ma'lumotlaringizni kiriting:

```yaml
environment:
  # Database ma'lumotlari
  PROJECT_NAME: my-project           # Loyiha nomi (fayl nomida ishlatiladi)
  PGHOST: postgres
  PGPORT: 5432
  PGUSER: postgres
  PGPASSWORD: your-password
  PGDATABASE: your-database
  
  # Backup sozlamalari
  BACKUP_PASSWORD: secure-password    # Parol bilan shifrlash (ixtiyoriy)
  MIN_LOCAL_BACKUPS: 2                # Minimal lokal fayllar soni
  MAX_LOCAL_BACKUPS: 10               # Maksimal lokal fayllar soni
  COMPRESSION_LEVEL: 9                # Siqish darajasi (0-9)
  
  # Rclone sozlamalari
  RCLONE_CONFIG: /etc/rclone/rclone.conf
  RCLONE_REMOTE: gdrive               # Rclone remote nomi
  RCLONE_PATH: backups/my-project     # Cloud'dagi papka yo'li
  
  # Jadvallar (Cron format)
  CRON_BACKUP_SCHEDULE: "0 2 * * *"   # Har kuni soat 2:00da
  CRON_UPLOAD_SCHEDULE: ""            # Bo'sh = backup bilan birga
  CRON_CLEANUP_SCHEDULE: ""           # Bo'sh = upload bilan birga
```

### 3️⃣ Ishga Tushirish

```bash
# Containerni ishga tushirish
docker-compose up -d backup

# Loglarni ko'rish
docker logs -f backup
```

---

## 🎛️ 3 ta Mustaqil Jarayon

Tizimda **3 ta asosiy jarayon** mavjud:

### 1. **BACKUP** - Ma'lumotlarni olish
```
✅ PostgreSQL dump yaratadi
✅ ZIP formatga siqadi
✅ Parol bilan shifrlaydi
✅ /backup papkaga saqlaydi
```

### 2. **UPLOAD** - Cloudga yuklash
```
✅ Lokal fayllarni topadi
✅ Cloudga yuklaydi (rclone)
✅ Yuklash vaqtini saqlaydi
```

### 3. **CLEANUP** - Eski fayllarni tozalash
```
✅ Yuklangan fayllarni o'chiradi
✅ MIN/MAX qoidalariga amal qiladi
✅ Disk joyini bo'shatadi
```

---

## ⚙️ Jadval Sozlamalari - 3 ta Variant

Sizda **3 ta o'zgaruvchi** bor - ularni qanday sozlashingizga qarab tizim turlicha ishlaydi:

### **Variant 1: Hammasi ketma-ket** ⭐ (Tavsiya etiladi)

```yaml
CRON_BACKUP_SCHEDULE: "*/10 * * * *"  # Har 10 daqiqada
CRON_UPLOAD_SCHEDULE: ""              # Bo'sh
CRON_CLEANUP_SCHEDULE: ""             # Bo'sh
```

**Natija:** 
```
Backup → Upload → Cleanup (bir jarayonda ketma-ket)
```

✅ **Afzalliklari:**
- Oddiy va tushunarli
- Bir vaqtda hamma ish bitadi
- Fayllar darhol cloudga yuklanadi va o'chiriladi

---

### **Variant 2: Hammasi mustaqil**

```yaml
CRON_BACKUP_SCHEDULE: "*/10 * * * *"  # Har 10 daqiqada
CRON_UPLOAD_SCHEDULE: "*/30 * * * *"  # Har 30 daqiqada
CRON_CLEANUP_SCHEDULE: "0 * * * *"    # Har soatda
```

**Natija:** 
```
Backup   → o'z vaqtida ishlaydi
Upload   → o'z vaqtida ishlaydi
Cleanup  → o'z vaqtida ishlaydi
```

✅ **Afzalliklari:**
- Tarmog'ida muammo bo'lsa, upload keyinroq qayta urinadi
- Har bir jarayon mustaqil
- Parallel ishlash mumkin

---

### **Variant 3: Backup mustaqil, Upload va Cleanup birga**

```yaml
CRON_BACKUP_SCHEDULE: "*/10 * * * *"  # Har 10 daqiqada
CRON_UPLOAD_SCHEDULE: "*/30 * * * *"  # Har 30 daqiqada
CRON_CLEANUP_SCHEDULE: ""             # Bo'sh
```

**Natija:** 
```
Backup → mustaqil
Upload → Cleanup (birga)
```

✅ **Afzalliklari:**
- Backup tez-tez
- Upload va tozalash birga
- Yuklanish bilan o'chirish parallel

---

## 📅 Cron Jadval Misollari

```bash
# Har 5 daqiqada
"*/5 * * * *"

# Har 30 daqiqada
"*/30 * * * *"

# Har soatda
"0 * * * *"

# Har kuni soat 2:30da
"30 2 * * *"

# Har kuni soat 0:00 va 12:00da
"0 0,12 * * *"

# Har dushanba soat 3:00da
"0 3 * * 1"

# Har oyning 1-kunida
"0 0 1 * *"

# Har ish kunida (Dushanba-Juma) soat 8:00da
"0 8 * * 1-5"
```

**Format:** `minute hour day month weekday`

**Online generator:** [crontab.guru](https://crontab.guru)

---

## 🔧 Muhim Sozlamalar

### MIN_LOCAL_BACKUPS va MAX_LOCAL_BACKUPS

**MIN_LOCAL_BACKUPS** - Eng kamida qancha backup saqlanishi kerak:
```yaml
MIN_LOCAL_BACKUPS: 2  # Kamida 2 ta backup doim lokal saqlanadi
```

**MAX_LOCAL_BACKUPS** - Eng ko'pi bilan qancha backup saqlanadi:
```yaml
MAX_LOCAL_BACKUPS: 10  # 10 dan ortiq bo'lsa, eng eskisi o'chiriladi
```

#### Qanday ishlaydi?

**Holat 1: MAX dan oshgan**
```
Lokal fayllar: 12 ta
MIN: 2
MAX: 10

✅ 12 > 10 (MAX dan oshgan!)
→ Eng eski 2 ta fayl DARHOL o'chiriladi
→ (Yuklanmagan bo'lsa ham o'chiriladi!)
→ Qoladi: 10 ta fayl
```

**Holat 2: MIN va MAX orasida**
```
Lokal fayllar: 7 ta
MIN: 2
MAX: 10

✅ 7 > 2 va 7 < 10 (MIN va MAX orasida)
→ FAQAT cloudga yuklangan 5 ta eski fayl o'chiriladi
→ Yuklanmagan fayllar SAQLANADI
→ Qoladi: 2 ta fayl (MIN)
```

**MUHIM:**
- **MAX dan oshsa** → Yuklanmagan bo'lsa ham o'chiriladi!
- **MIN va MAX orasida** → Faqat yuklangan fayllar o'chiriladi

---

### BACKUP_PASSWORD

Backup fayllarni parol bilan shifrlash (ixtiyoriy):

```yaml
BACKUP_PASSWORD: "my-secure-password-123"
```

✅ **Parol bor** → ZIP fayllar parol bilan himoyalangan  
❌ **Bo'sh** → Oddiy ZIP (shifrlashsiz)

**Parolni tiklash:**
```bash
# ZIP faylni ochish
unzip -P your-password backup.zip
```

---

### COMPRESSION_LEVEL

ZIP siqish darajasi (0-9):

```yaml
COMPRESSION_LEVEL: 9  # 9 = maksimal siqish (sekinroq, kichik fayl)
COMPRESSION_LEVEL: 6  # 6 = muvozanatli (o'rtacha)
COMPRESSION_LEVEL: 1  # 1 = minimal siqish (tezroq, katta fayl)
```

---

## 🔄 Tizim Qanday Ishlaydi?

### 1. **Backup Jarayoni (backup.sh)**

```
1️⃣ PostgreSQL dump yaratadi (pg_dump)
2️⃣ ZIP formatga siqadi (compression level)
3️⃣ Parol bilan shifrlaydi (agar parol bor bo'lsa)
4️⃣ /backup papkaga saqlaydi
5️⃣ Vaqtni .backup_state faylga yozadi
6️⃣ Agar CRON_UPLOAD_SCHEDULE bo'sh → upload.sh ni chaqiradi
7️⃣ Aks holda → tugaydi (upload keyinroq ishlaydi)
```

**Yaratilgan fayl:** `project-name_database-name_20241217_143000.zip`

---

### 2. **Upload Jarayoni (upload.sh)**

```
1️⃣ Barcha .zip fayllarni topadi
2️⃣ Oxirgi uploaddan keyingi fayllarni filtrlaydi
3️⃣ Har birini cloudga yuklaydi (rclone copy)
4️⃣ Muvaffaqiyatli yuklanganlarni hisobga oladi
5️⃣ Upload vaqtini .backup_state faylga yozadi
6️⃣ Agar CRON_CLEANUP_SCHEDULE bo'sh → cleanup.sh ni chaqiradi
7️⃣ Aks holda → tugaydi (cleanup keyinroq ishlaydi)
```

**Xususiyat:** Internet yo'q bo'lsa, fayllar lokal saqlanadi va keyingi uploadda yuklashga harakat qilinadi.

---

### 3. **Cleanup Jarayoni (cleanup.sh)**

```
1️⃣ Barcha .zip fayllarni sanaydi
2️⃣ Oxirgi upload vaqtini tekshiradi
3️⃣ MAX_LOCAL_BACKUPS dan oshganini tekshiradi:
   
   📊 MAX dan oshgan:
   → Eng eski fayllarni o'chiradi (yuklanmagan bo'lsa ham!)
   
   📊 MIN va MAX orasida:
   → FAQAT yuklangan eski fayllarni o'chiradi
   → Yuklanmagan fayllar SAQLANADI
   
4️⃣ MIN_LOCAL_BACKUPS miqdori DOIM saqlanadi
```

---

## 📊 Loglarni Ko'rish

```bash
# Real-time loglar
docker logs -f backup

# Oxirgi 50 qator
docker logs --tail 50 backup

# State faylni ko'rish
docker exec backup cat /backup/.backup_state
```

**State fayl misoli:**
```bash
LAST_BACKUP=1734428100
LAST_UPLOAD=1734428105
```

---

## 🛠️ Foydali Buyruqlar

```bash
# Manual backup yaratish
docker exec backup /usr/local/bin/backup.sh

# Manual upload
docker exec backup /usr/local/bin/upload.sh

# Manual cleanup
docker exec backup /usr/local/bin/cleanup.sh

# Rclone konfiguratsiyasini ko'rish
docker exec backup rclone config show

# Rclone remote'larni ko'rish
docker exec backup rclone listremotes

# Cloud fayllarni ko'rish
docker exec backup rclone ls gdrive:backups/my-project

# Container holatini tekshirish
docker ps | grep backup

# Cron jadvalini ko'rish
docker exec backup crontab -l
```

---

## 📁 Fayl Tuzilishi

```
.
├── backup/
│   ├── Dockerfile              # Docker image
│   ├── entrypoint.sh           # Asosiy entry point
│   ├── backup.sh               # Backup yaratish
│   ├── upload.sh               # Cloudga yuklash
│   ├── cleanup.sh              # Tozalash
│   └── rclone.conf             # Rclone sozlamalari
├── data/
│   ├── backup/                 # Lokal backup fayllar
│   │   ├── .backup_state       # Holat fayli (avtomatik)
│   │   └── *.zip               # Backup ZIP fayllar
│   └── pgdata/                 # PostgreSQL ma'lumotlari
└── docker-compose.yml          # Docker Compose config
```

---

## 🔐 Xavfsizlik

- ✅ Parollar environment variables orqali uzatiladi
- ✅ Rclone config read-only rejimda
- ✅ PGPASSWORD runtime'da o'chiriladi
- ✅ Backup fayllar parol bilan shifrlanadi
- ✅ Logda parollar ko'rinmaydi

---

## 💡 Maslahatlar

### 1. **Birinchi test qiling**
```yaml
# Qisqa interval bilan test
CRON_BACKUP_SCHEDULE: "*/1 * * * *"  # Har daqiqada
CRON_UPLOAD_SCHEDULE: ""
CRON_CLEANUP_SCHEDULE: ""
```

Bir necha daqiqa kuzating, keyin production sozlamalariga o'ting.

---

### 2. **Production uchun**
```yaml
# Kuniga 2 marta
CRON_BACKUP_SCHEDULE: "0 2,14 * * *"  # 02:00 va 14:00
CRON_UPLOAD_SCHEDULE: ""               # Backup bilan birga
CRON_CLEANUP_SCHEDULE: ""              # Upload bilan birga
```

---

### 3. **Internet tez-tez uzilsa**
```yaml
# Backup tez-tez, upload kamroq
CRON_BACKUP_SCHEDULE: "*/10 * * * *"  # Har 10 daqiqada
CRON_UPLOAD_SCHEDULE: "*/30 * * * *"  # Har 30 daqiqada
CRON_CLEANUP_SCHEDULE: ""             # Upload bilan birga
```

Bu internet yo'q bo'lganda ham lokal backuplar saqlanadi.

---

### 4. **MIN va MAX to'g'ri sozlang**

**Kichik loyihalar uchun:**
```yaml
MIN_LOCAL_BACKUPS: 1
MAX_LOCAL_BACKUPS: 5
```

**O'rta loyihalar uchun:**
```yaml
MIN_LOCAL_BACKUPS: 2
MAX_LOCAL_BACKUPS: 10
```

**Katta loyihalar uchun:**
```yaml
MIN_LOCAL_BACKUPS: 3
MAX_LOCAL_BACKUPS: 20
```

---

## 📞 Yordam

Muammolar yoki savollar uchun GitHub Issues'ga murojaat qiling.

---

## 📝 Lisenziya

MIT License - erkin foydalanishingiz mumkin! 🎉