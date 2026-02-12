#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
BACKUP_ROOT="/var/backups/solar-assistant/influx"
TMP_DIR="/tmp/sa-influx-backup"
KEEP_DAYS_LOCAL=14

# FTP target (обычный FTP)
FTP_HOST="ftp.example.com"
FTP_USER="ftpuser"
FTP_PASS="ftppassword"
FTP_DIR="/backups/solar-assistant/influx"   # папка на FTP

# Influx backup command
INFLUX_BACKUP_CMD="influxd backup -portable"
# ====================

TS_UTC="$(date -u +%Y%m%dT%H%M%SZ)"
DATE_LOCAL="$(date +%F)"
HOSTNAME_SHORT="$(hostname -s || hostname)"
PREV_DAY_LOCAL="$(date -d 'yesterday' +%F)"
PREV_DAY_START_ISO="$(date -d 'yesterday 00:00:00' --iso-8601=seconds)"
TODAY_START_ISO="$(date -d 'today 00:00:00' --iso-8601=seconds)"

ARCHIVE_DIR="${BACKUP_ROOT}/${DATE_LOCAL}"
FULL_ARCHIVE_NAME="sa-influx-${HOSTNAME_SHORT}-${TS_UTC}-full.tar.gz"
FULL_ARCHIVE_PATH="${ARCHIVE_DIR}/${FULL_ARCHIVE_NAME}"

DAILY_TMP_DIR="${TMP_DIR}-daily"
DAILY_ARCHIVE_NAME="sa-influx-${HOSTNAME_SHORT}-${PREV_DAY_LOCAL}-daily.tar.gz"
DAILY_ARCHIVE_PATH="${ARCHIVE_DIR}/${DAILY_ARCHIVE_NAME}"

log() { echo "[$(date -Is)] $*"; }

cleanup() {
  rm -rf "${TMP_DIR}" || true
  rm -rf "${DAILY_TMP_DIR}" || true
}
trap cleanup EXIT

log "Create dirs..."
mkdir -p "${ARCHIVE_DIR}"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
rm -rf "${DAILY_TMP_DIR}"
mkdir -p "${DAILY_TMP_DIR}"

log "Running full InfluxDB backup..."
${INFLUX_BACKUP_CMD} "${TMP_DIR}/"

log "Packing full archive: ${FULL_ARCHIVE_PATH}"
tar -C "${TMP_DIR}" -czf "${FULL_ARCHIVE_PATH}" .

log "Running previous-day InfluxDB backup (${PREV_DAY_START_ISO} -> ${TODAY_START_ISO})..."
${INFLUX_BACKUP_CMD} -start "${PREV_DAY_START_ISO}" -end "${TODAY_START_ISO}" "${DAILY_TMP_DIR}/"

log "Packing previous-day archive: ${DAILY_ARCHIVE_PATH}"
tar -C "${DAILY_TMP_DIR}" -czf "${DAILY_ARCHIVE_PATH}" .

log "Uploading to FTP..."
lftp -u "${FTP_USER}","${FTP_PASS}" "${FTP_HOST}" <<EOF
set ftp:ssl-allow no
set net:timeout 20
set net:max-retries 3
set net:reconnect-interval-base 5
set cmd:fail-exit yes
mkdir -p ${FTP_DIR}/${DATE_LOCAL}
cd ${FTP_DIR}/${DATE_LOCAL}
put "${FULL_ARCHIVE_PATH}"
put "${DAILY_ARCHIVE_PATH}"
bye
EOF

log "FTP upload OK"

log "Local rotation: delete backups older than ${KEEP_DAYS_LOCAL} days..."
find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d -mtime +"${KEEP_DAYS_LOCAL}" -print -exec rm -rf {} \;

log "Done"
