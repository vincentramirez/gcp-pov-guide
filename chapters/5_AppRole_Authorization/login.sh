#!/usr/bin/env bash
APP_ROLE_TOKEN=$(curl -X POST -d '{"role_id": "'"$ROLE_ID"'", "secret_id": "'"$SECRET_ID"'"}' $VAULT_ADDR/v1/auth/approle/login | jq -r '.auth.client_token')
