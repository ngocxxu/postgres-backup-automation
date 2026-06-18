#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Cleaning Up Old Backups ===${NC}"

RETENTION_DAYS="${RETENTION_DAYS:-30}"
echo "Retention policy: $RETENTION_DAYS days"

source "$(dirname "$0")/b2-install.sh"

b2 authorize-account "$B2_ACCOUNT_ID" "$B2_APPLICATION_KEY" > /dev/null

CUTOFF_TIMESTAMP=$(date -d "$RETENTION_DAYS days ago" +%s 2>/dev/null || date -v-${RETENTION_DAYS}d +%s)
CUTOFF_DATE=$(date -d @$CUTOFF_TIMESTAMP +%Y%m%d 2>/dev/null || date -r $CUTOFF_TIMESTAMP +%Y%m%d)

echo "Cutoff date: $CUTOFF_DATE"
echo -e "${YELLOW}Scanning for old backups...${NC}"

DELETED_COUNT=0

while IFS= read -r line; do
  FILENAME=$(echo "$line" | awk '{print $NF}')
  FILE_DATE=$(echo "$FILENAME" | grep -oP '\d{8}' | head -1 || echo "")

  if [ -n "$FILE_DATE" ] && [ "$FILE_DATE" -lt "$CUTOFF_DATE" ]; then
    echo "Deleting: $FILENAME (date: $FILE_DATE)"
    FILE_INFO=$(b2 ls --long "$B2_BUCKET_NAME" "$FILENAME" 2>/dev/null | head -1)
    FILE_ID=$(echo "$FILE_INFO" | awk '{print $1}')

    if [ -n "$FILE_ID" ]; then
      b2 delete-file-version "$FILENAME" "$FILE_ID" && \
        echo "  ✓ Deleted" && \
        DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
  fi
done < <(b2 ls --recursive "$B2_BUCKET_NAME" backups/)

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo "Deleted $DELETED_COUNT old backup(s)"
