#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Uploading to Backblaze B2 ===${NC}"

if [ -f "/tmp/pg-backups/backup-info.env" ]; then
  source /tmp/pg-backups/backup-info.env
fi

[[ -n "${BACKUP_FILE:-}" ]] || { echo -e "${RED}ERROR: BACKUP_FILE not set${NC}"; exit 1; }
[[ -n "${BACKUP_PATH:-}" ]] || { echo -e "${RED}ERROR: BACKUP_PATH not set${NC}"; exit 1; }

if [ ! -f "$BACKUP_PATH" ]; then
  echo -e "${RED}ERROR: Backup file not found: $BACKUP_PATH${NC}"
  exit 1
fi

source "$(dirname "$0")/b2-install.sh"

echo -e "${YELLOW}Authorizing with B2...${NC}"
export B2_APPLICATION_KEY_ID="$B2_ACCOUNT_ID"
b2 account authorize > /dev/null

echo -e "${YELLOW}Uploading $BACKUP_FILE...${NC}"
b2 file upload \
  --content-type "application/gzip" \
  "$B2_BUCKET_NAME" \
  "$BACKUP_PATH" \
  "backups/$BACKUP_FILE"

echo -e "${YELLOW}Verifying upload...${NC}"
echo "DEBUG: b2 ls b2://$B2_BUCKET_NAME/backups/$BACKUP_FILE"
b2 ls "b2://$B2_BUCKET_NAME/backups/$BACKUP_FILE" 2>&1 || true
echo "DEBUG: b2 ls exit code: $?"
echo "DEBUG: b2 ls bucket root:"
b2 ls "b2://$B2_BUCKET_NAME/backups/" 2>&1 | head -5 || true
if b2 ls "b2://$B2_BUCKET_NAME/backups/$BACKUP_FILE" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Upload successful${NC}"
  B2_URL=$(b2 file url "b2://$B2_BUCKET_NAME/backups/$BACKUP_FILE" 2>/dev/null || echo "N/A")
  echo "B2_URL=$B2_URL" >> /tmp/pg-backups/backup-info.env
else
  echo -e "${RED}ERROR: Upload verification failed${NC}"
  exit 1
fi

echo -e "${GREEN}=== Upload completed ===${NC}"
