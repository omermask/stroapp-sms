#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

BACKUP_DIR="${BACKUP_DIR:-/tmp/stroapp-backups}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <backup-file>"
    echo ""
    echo "Available backups:"
    ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null || echo "  (no backups found in $BACKUP_DIR)"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

export $(grep -v '^#' .env 2>/dev/null | xargs)

DB_URL="${DATABASE_URL:-}"

if [ -z "$DB_URL" ]; then
    echo "ERROR: DATABASE_URL not set in .env"
    exit 1
fi

echo "WARNING: This will overwrite the current database!"
read -rp "Are you sure? (Type 'yes' to continue): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo "Starting restore from: $BACKUP_FILE"
psql "$DB_URL" -f "$BACKUP_FILE"
echo "Restore complete"
