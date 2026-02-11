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

ARCHIVE_DIR="${BACKUP_ROOT}/${DATE_LOCAL}"
ARCHIVE_NAME="sa-influx-${HOSTNAME_SHORT}-${TS_UTC}.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"

log() { echo "[$(date -Is)] $*"; }

cleanup() { rm -rf "${TMP_DIR}" || true; }
trap cleanup EXIT

log "Create dirs..."
mkdir -p "${ARCHIVE_DIR}"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

log "Running InfluxDB backup..."
${INFLUX_BACKUP_CMD} "${TMP_DIR}/"

log "Packing archive: ${ARCHIVE_PATH}"
tar -C "${TMP_DIR}" -czf "${ARCHIVE_PATH}" .

log "Uploading to FTP..."
lftp -u "${FTP_USER}","${FTP_PASS}" "${FTP_HOST}" <<EOF
set ftp:ssl-allow no
set net:timeout 20
set net:max-retries 3
set net:reconnect-interval-base 5
set cmd:fail-exit yes
mkdir -p ${FTP_DIR}/${DATE_LOCAL}
cd ${FTP_DIR}/${DATE_LOCAL}
put "${ARCHIVE_PATH}"
bye
EOF

log "FTP upload OK"

log "Local rotation: delete backups older than ${KEEP_DAYS_LOCAL} days..."
find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d -mtime +"${KEEP_DAYS_LOCAL}" -print -exec rm -rf {} \;

log "Done"
