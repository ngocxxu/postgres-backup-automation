#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== PostgreSQL Backup Script ===${NC}"
echo "Started at: $(date)"

NAMESPACE="${POSTGRES_NAMESPACE:-default}"
LABEL_SELECTOR="${POSTGRES_LABEL_SELECTOR}"
DB_NAME="${POSTGRES_DB}"
DB_USER="${POSTGRES_USER}"
DB_PASSWORD="${POSTGRES_PASSWORD}"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/pg-backups"
BACKUP_FILE="postgres_${DB_NAME}_${DATE}.sql.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Finding PostgreSQL pod...${NC}"
echo "DEBUG: NAMESPACE=$NAMESPACE"
echo "DEBUG: LABEL_SELECTOR=$LABEL_SELECTOR"
echo "DEBUG: kubectl context: $(kubectl config current-context 2>/dev/null || echo 'NO CONTEXT')"
echo "DEBUG: All pods in namespace '$NAMESPACE':"
kubectl get pods -n "$NAMESPACE" --show-labels 2>&1 || echo "DEBUG: kubectl get pods FAILED (exit $?)"

POSTGRES_POD=$(kubectl get pods -n "$NAMESPACE" \
  -l "$LABEL_SELECTOR" \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

echo "DEBUG: Resolved POSTGRES_POD='$POSTGRES_POD'"

if [ -z "$POSTGRES_POD" ]; then
  echo -e "${RED}ERROR: No PostgreSQL pod found with label: $LABEL_SELECTOR${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Found pod: $POSTGRES_POD${NC}"

POD_STATUS=$(kubectl get pod -n "$NAMESPACE" "$POSTGRES_POD" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
  echo -e "${RED}ERROR: Pod is not running (status: $POD_STATUS)${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Pod is running${NC}"

echo -e "${YELLOW}Creating database backup...${NC}"
kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" \
  -- env PGPASSWORD="$DB_PASSWORD" pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner --no-acl \
  | gzip -9 > "$BACKUP_PATH"

if [ ! -f "$BACKUP_PATH" ]; then
  echo -e "${RED}ERROR: Backup file not created${NC}"
  exit 1
fi

FILE_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
FILE_SIZE_BYTES=$(stat -f%z "$BACKUP_PATH" 2>/dev/null || stat -c%s "$BACKUP_PATH" 2>/dev/null)

if [ "$FILE_SIZE_BYTES" -lt 1000 ]; then
  echo -e "${RED}ERROR: Backup file too small (${FILE_SIZE}), possibly empty${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Backup created successfully${NC}"
echo -e "  ${BLUE}File: $BACKUP_FILE${NC}"
echo -e "  ${BLUE}Size: $FILE_SIZE${NC}"
echo -e "  ${BLUE}Path: $BACKUP_PATH${NC}"

POSTGRES_VERSION=$(kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- psql --version | head -1)

cat > "$BACKUP_DIR/backup-info.env" << EOL
BACKUP_FILE=$BACKUP_FILE
BACKUP_PATH=$BACKUP_PATH
BACKUP_SIZE=$FILE_SIZE
POSTGRES_POD=$POSTGRES_POD
POSTGRES_VERSION="$POSTGRES_VERSION"
EOL

echo -e "${GREEN}=== Backup completed at $(date) ===${NC}"
