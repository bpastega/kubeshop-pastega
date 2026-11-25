#!/usr/bin/env bash
set -euo pipefail
LOCATION="${LOCATION:-chilecentral}"
RG=rg-kubeshop-bootstrap
SA="stkubeshop$RANDOM"        # nome global, 3-24 letras minúsculas/números
APP_ID="$1"                     # appId da identidade da pipeline

az group create -n "$RG" -l "$LOCATION" -o none
az storage account create -n "$SA" -g "$RG" -l "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
  --allow-blob-public-access false -o none

# proteção do state: versionamento + soft delete de 14 dias
az storage account blob-service-properties update -n "$SA" -g "$RG" \
  --enable-versioning true --enable-delete-retention true --delete-retention-days 14 -o none

SA_ID=$(az storage account show -n "$SA" -g "$RG" --query id -o tsv)
# a pipeline (e você) acessam os blobs via Entra ID, sem chave da conta
az role assignment create --assignee "$APP_ID" --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none
az role assignment create --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none
sleep 60   # propagação do RBAC

az storage container create -n tfstate --account-name "$SA" --auth-mode login -o none
az storage container create -n backups --account-name "$SA" --auth-mode login -o none

# retenção dos backups: apaga blobs com mais de 30 dias
az storage account management-policy create --account-name "$SA" -g "$RG" --policy '{
  "rules":[{"enabled":true,"name":"expira-backups","type":"Lifecycle",
  "definition":{"filters":{"blobTypes":["blockBlob"],"prefixMatch":["backups/"]},
  "actions":{"baseBlob":{"delete":{"daysAfterModificationGreaterThan":30}}}}}]}' -o none

echo "TFSTATE_RG=$RG TFSTATE_SA=$SA TFSTATE_CONTAINER=tfstate"
