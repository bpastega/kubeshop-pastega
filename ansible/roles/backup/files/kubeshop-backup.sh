#!/usr/bin/env bash
# ansible/roles/backup/files/kubeshop-backup.sh (copiado para /usr/local/bin/kubeshop-backup.sh)
# o #!/usr/bin/env bash precisa ser a primeira linha do arquivo
set -euo pipefail
TS=$(date -u +%Y%m%dT%H%M%SZ)
OUT="/data/backups/kubeshop-$TS.archive.gz"
# a senha vem do ambiente do próprio contêiner: nada de senha no script
docker exec mongo sh -c 'mongodump -u root -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin --db "$MONGO_APP_DB" --archive --gzip' > "$OUT"
find /data/backups -name 'kubeshop-*.archive.gz' -mtime +7 -delete
echo "$OUT"
