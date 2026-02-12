# Solar Assistant InfluxDB Backup to FTP

## English

Nightly **portable** InfluxDB backup (Solar Assistant) → packed into `tar.gz` → uploaded to **FTP** via `lftp` → local day-based rotation.

---

### What it does

- Runs a full backup: `influxd backup -portable`
- Runs a separate backup for the previous day (midnight to midnight): `influxd backup -portable -start ... -end ...`
- Packs both results into `*.tar.gz` archives
- Uploads both archives to FTP into a date folder (`YYYY-MM-DD`)
- Removes **local** backups older than `KEEP_DAYS_LOCAL` days

---

### Backup structure

#### Local

Folders are created by date:

```
/var/backups/solar-assistant/influx/
└── 2026-02-11/
    ├── sa-influx-solar-assistant-20260211T031501Z-full.tar.gz
    └── sa-influx-solar-assistant-2026-02-10-daily.tar.gz
```

#### FTP

Files are uploaded in the same date-based structure:

```
<FTP_DIR>/
└── 2026-02-11/
    ├── sa-influx-solar-assistant-20260211T031501Z-full.tar.gz
    └── sa-influx-solar-assistant-2026-02-10-daily.tar.gz
```

> ⚠️ FTP rotation is **not** enabled by default: files accumulate until you clean them up manually or add cleanup logic.

---

### Requirements

- Linux (Debian/Ubuntu/Solar Assistant OS)
- `influxd` available in the system
- `lftp`

Install `lftp`:

```bash
sudo apt update
sudo apt install -y lftp
```

---

### Installation

#### 1) Install the script

```bash
sudo install -m 0755 scripts/sa_influx_backup_to_ftp.sh \
  /usr/local/bin/sa_influx_backup_to_ftp.sh
```

#### 2) Configure parameters

Open the script and fill in FTP settings:

```bash
sudo nano /usr/local/bin/sa_influx_backup_to_ftp.sh
```

Minimum required:

- `FTP_HOST`
- `FTP_USER`
- `FTP_PASS`
- `FTP_DIR`

Optional:

- `BACKUP_ROOT`
- `KEEP_DAYS_LOCAL`

---

### Install systemd service and timer

#### 1) Copy unit files

```bash
sudo install -m 0644 systemd/sa-influx-backup.service \
  /etc/systemd/system/sa-influx-backup.service

sudo install -m 0644 systemd/sa-influx-backup.timer \
  /etc/systemd/system/sa-influx-backup.timer
```

#### 2) Enable timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sa-influx-backup.timer
```

---

### Manual run (one-shot)

Run the service manually:

```bash
sudo systemctl start sa-influx-backup.service
```

---

### Status checks

Timer:

```bash
systemctl status sa-influx-backup.timer
```

Service:

```bash
systemctl status sa-influx-backup.service
```

Show scheduler entries:

```bash
systemctl list-timers | grep sa-influx
```

---

### Logs

```bash
sudo journalctl -u sa-influx-backup.service -n 200 --no-pager
```

---

### Schedule

Default (in timer file):

- every day at **03:15**

Line:

```ini
OnCalendar=*-*-* 03:15:00
```

---

### Rotation

#### Local

Configured by:

- `KEEP_DAYS_LOCAL=14`

The script removes **day directories** older than this value.

#### FTP

Not implemented in this version.

---

### Security

Currently, the FTP password is stored directly in the script — convenient for a quick start, but not ideal.

Recommendations (best practices):

- move credentials to a systemd `EnvironmentFile` with `600` permissions
- or use `.netrc` (also `chmod 600`)
- migrate to **SFTP/FTPS** when possible

---

### Quick test without systemd

```bash
sudo /usr/local/bin/sa_influx_backup_to_ftp.sh
```

---

### License

MIT

---

## Українська

Нічний **portable** бекап InfluxDB (Solar Assistant) → пакування в `tar.gz` → завантаження на **FTP** через `lftp` → локальна ротація за днями.

---

### Що робить

- Запускає повний бекап: `influxd backup -portable`
- Запускає окремий бекап за попередню добу (від півночі до півночі): `influxd backup -portable -start ... -end ...`
- Пакує обидва результати в архіви `*.tar.gz`
- Завантажує обидва архіви на FTP у папку за датою (`YYYY-MM-DD`)
- Видаляє **локальні** бекапи старші за `KEEP_DAYS_LOCAL` днів

---

### Структура бекапів

#### Локально

Папки створюються за датою:

```
/var/backups/solar-assistant/influx/
└── 2026-02-11/
    ├── sa-influx-solar-assistant-20260211T031501Z-full.tar.gz
    └── sa-influx-solar-assistant-2026-02-10-daily.tar.gz
```

#### На FTP

Файли завантажуються так само за датою:

```
<FTP_DIR>/
└── 2026-02-11/
    ├── sa-influx-solar-assistant-20260211T031501Z-full.tar.gz
    └── sa-influx-solar-assistant-2026-02-10-daily.tar.gz
```

> ⚠️ На FTP ротація за замовчуванням **не** увімкнена: файли накопичуються, доки їх не видалити вручну або не додати cleanup-логіку.

---

### Вимоги

- Linux (Debian/Ubuntu/Solar Assistant OS)
- `influxd` доступний у системі
- `lftp`

Встановити `lftp`:

```bash
sudo apt update
sudo apt install -y lftp
```

---

### Встановлення

#### 1) Встановити скрипт

```bash
sudo install -m 0755 scripts/sa_influx_backup_to_ftp.sh \
  /usr/local/bin/sa_influx_backup_to_ftp.sh
```

#### 2) Налаштувати параметри

Відкрийте скрипт і заповніть FTP-параметри:

```bash
sudo nano /usr/local/bin/sa_influx_backup_to_ftp.sh
```

Мінімально потрібно змінити:

- `FTP_HOST`
- `FTP_USER`
- `FTP_PASS`
- `FTP_DIR`

Опційно:

- `BACKUP_ROOT`
- `KEEP_DAYS_LOCAL`

---

### Встановлення systemd service і timer

#### 1) Скопіювати unit-файли

```bash
sudo install -m 0644 systemd/sa-influx-backup.service \
  /etc/systemd/system/sa-influx-backup.service

sudo install -m 0644 systemd/sa-influx-backup.timer \
  /etc/systemd/system/sa-influx-backup.timer
```

#### 2) Увімкнути таймер

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sa-influx-backup.timer
```

---

### Ручний запуск (one-shot)

Запуск сервісу вручну:

```bash
sudo systemctl start sa-influx-backup.service
```

---

### Перевірка статусу

Таймер:

```bash
systemctl status sa-influx-backup.timer
```

Сервіс:

```bash
systemctl status sa-influx-backup.service
```

Показати планувальник:

```bash
systemctl list-timers | grep sa-influx
```

---

### Логи

```bash
sudo journalctl -u sa-influx-backup.service -n 200 --no-pager
```

---

### Розклад

За замовчуванням (у timer-файлі):

- щодня о **03:15**

Рядок:

```ini
OnCalendar=*-*-* 03:15:00
```

---

### Ротація

#### Локально

Задається змінною:

- `KEEP_DAYS_LOCAL=14`

Скрипт видаляє **каталоги днів**, старші за це значення.

#### На FTP

Не реалізовано в цій версії.

---

### Безпека

Зараз пароль FTP зберігається прямо у скрипті — це зручно для швидкого старту, але не ідеально.

Рекомендації (best practices):

- винести облікові дані в systemd `EnvironmentFile` з правами `600`
- або використовувати `.netrc` (також `chmod 600`)
- за можливості перейти на **SFTP/FTPS**

---

### Швидкий тест без systemd

```bash
sudo /usr/local/bin/sa_influx_backup_to_ftp.sh
```

---

### Ліцензія

MIT
