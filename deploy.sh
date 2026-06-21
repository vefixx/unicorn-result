#!/bin/bash
set -e

DB_NAME="${1:-test.sqlite}"
METABASE_PORT=3000

if [ ! -f "init_all.sql" ]; then
    echo "init_all.sql not found in current directory"
    exit 1
fi

if [ -f "$DB_NAME" ]; then
    BACKUP_NAME="${DB_NAME}.backup_$(date +%Y%m%d_%H%M%S)"
    mv "$DB_NAME" "$BACKUP_NAME"
    echo "Backup created $BACKUP_NAME"
fi

sqlite3 "$DB_NAME" "VACUUM;"
sqlite3 "$DB_NAME" < init_all.sql

sqlite3 "$DB_NAME" "PRAGMA wal_checkpoint(TRUNCATE);"

docker stop metabase 2>/dev/null || true
docker rm metabase 2>/dev/null || true

docker run -d \
  --name metabase \
  --restart=unless-stopped \
  --memory=2g \
  -p "$METABASE_PORT:3000" \
  -v "$(pwd):/app/data" \
  -e JAVA_OPTS="-Xmx1g" \
  metabase/metabase:latest

echo "Metabase started on port $METABASE_PORT"
echo "Database file: $(pwd)/$DB_NAME"
echo "Connect to database in Metabase with path: /app/data/$DB_NAME"