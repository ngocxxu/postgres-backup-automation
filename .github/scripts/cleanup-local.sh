#!/bin/bash
set -euo pipefail

echo "=== Cleaning up local backup files ==="

BACKUP_DIR="/tmp/pg-backups"

if [ -d "$BACKUP_DIR" ]; then
  find "$BACKUP_DIR" -name "*.sql.gz" -mtime +1 -delete
  rm -f "$BACKUP_DIR/backup-info.env"
  echo "✓ Local cleanup completed"
fi
