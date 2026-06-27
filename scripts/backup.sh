#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

BACKUP_DIR="${BACKUP_DIR:-/tmp/stroapp-backups}"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)
FILENAME="stroapp_backup_${TIMESTAMP}.sql"
FILEPATH="${BACKUP_DIR}/${FILENAME}"

export $(grep -v '^#' .env 2>/dev/null | xargs)

DB_URL="${DATABASE_URL:-}"

if [ -z "$DB_URL" ]; then
    echo "ERROR: DATABASE_URL not set in .env"
    exit 1
fi

echo "Starting backup..."
echo "  Output: $FILEPATH"

pg_dump "$DB_URL" --no-owner --no-acl -f "$FILEPATH"

if [ $? -eq 0 ]; then
    SIZE=$(stat -c%s "$FILEPATH" 2>/dev/null || stat -f%z "$FILEPATH" 2>/dev/null)
    echo "Backup complete: $FILENAME ($SIZE bytes)"
else
    echo "Backup FAILED"
    exit 1
fi

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "stroapp_backup_*.sql" -mtime "+$RETENTION_DAYS" -delete

echo "Done"
