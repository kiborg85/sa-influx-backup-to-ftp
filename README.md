
# Solar Assistant InfluxDB Backup to FTP

Ночной **portable** бэкап InfluxDB (Solar Assistant) → упаковка в `tar.gz` → загрузка на **FTP** через `lftp` → локальная ротация по дням.

---

## Что делает

- Запускает полный бэкап: `influxd backup -portable`
- Запускает отдельный бэкап за предыдущие сутки (от полуночи до полуночи): `influxd backup -portable -start ... -end ...`
- Упаковывает оба результата в архивы `*.tar.gz`
- Загружает оба архива на FTP в папку по дате (`YYYY-MM-DD`)
- Удаляет **локальные** бэкапы старше `KEEP_DAYS_LOCAL` дней

---

## Структура бэкапов

### Локально

Папки создаются по дате:

```

/var/backups/solar-assistant/influx/
└── 2026-02-11/
└── sa-influx-solar-assistant-20260211T031501Z-full.tar.gz
└── sa-influx-solar-assistant-2026-02-10-daily.tar.gz

```

### На FTP

Файлы загружаются так же по дате:

```

<FTP_DIR>/
└── 2026-02-11/
└── sa-influx-solar-assistant-20260211T031501Z-full.tar.gz
└── sa-influx-solar-assistant-2026-02-10-daily.tar.gz

````

> ⚠️ На FTP по умолчанию **нет** ротации: файлы копятся, пока не удалить вручную или не добавить cleanup.

---

## Требования

- Linux (Debian/Ubuntu/Solar Assistant OS)
- `influxd` доступен в системе
- `lftp`

Установить `lftp`:

```bash
sudo apt update
sudo apt install -y lftp
````

---

## Установка

### 1) Установить скрипт

```bash
sudo install -m 0755 scripts/sa_influx_backup_to_ftp.sh \
  /usr/local/bin/sa_influx_backup_to_ftp.sh
```

### 2) Настроить параметры

Открой скрипт и заполни FTP параметры:

```bash
sudo nano /usr/local/bin/sa_influx_backup_to_ftp.sh
```

Минимально нужно изменить:

* `FTP_HOST`
* `FTP_USER`
* `FTP_PASS`
* `FTP_DIR`

Опционально:

* `BACKUP_ROOT`
* `KEEP_DAYS_LOCAL`

---

## Установка systemd service и timer

### 1) Скопировать unit-файлы

```bash
sudo install -m 0644 systemd/sa-influx-backup.service \
  /etc/systemd/system/sa-influx-backup.service

sudo install -m 0644 systemd/sa-influx-backup.timer \
  /etc/systemd/system/sa-influx-backup.timer
```

### 2) Включить таймер

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sa-influx-backup.timer
```

---

## Ручной запуск (one-shot)

Запуск сервиса вручную:

```bash
sudo systemctl start sa-influx-backup.service
```

---

## Проверка статуса

Таймер:

```bash
systemctl status sa-influx-backup.timer
```

Сервис:

```bash
systemctl status sa-influx-backup.service
```

Показать планировщик:

```bash
systemctl list-timers | grep sa-influx
```

---

## Логи

```bash
sudo journalctl -u sa-influx-backup.service -n 200 --no-pager
```

---

## Расписание

По умолчанию (в timer-файле):

* каждый день в **03:15**

Строка:

```ini
OnCalendar=*-*-* 03:15:00
```

---

## Ротация

### Локально

Задаётся переменной:

* `KEEP_DAYS_LOCAL=14`

Скрипт удаляет **каталоги дней** старше этого значения.

### На FTP

Не реализована в этой версии.

---

## Безопасность

Сейчас пароль FTP хранится прямо в скрипте — это удобно для быстрого старта, но не идеально.

Рекомендации (лучшие практики):

* вынести креды в systemd `EnvironmentFile` с правами `600`
* или использовать `.netrc` (тоже `chmod 600`)
* по возможности перейти на **SFTP/FTPS**

---

## Быстрый тест без systemd

```bash
sudo /usr/local/bin/sa_influx_backup_to_ftp.sh
```

---

## Лицензия

MIT

```
```
