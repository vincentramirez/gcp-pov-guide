ROLE_ID=$(curl -H "X-Vault-Token: $1" "$VAULT_ADDR/v1/auth/approle/role/$2/role-id" | jq -r '.data.role_id')
