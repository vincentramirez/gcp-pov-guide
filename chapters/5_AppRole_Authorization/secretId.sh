SECRET_ID=$(curl -X POST -H "X-Vault-Token: $1" "$VAULT_ADDR/v1/auth/approle/role/$2/secret-id" | jq -r '.data.secret_id')
