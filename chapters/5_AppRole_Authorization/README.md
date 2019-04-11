# Chapter 5: AppRole Authorization
AppRole is a non cloud authorization pattern for applications. The general idea is some service in an automated process needs a way to login and retrieve secrets to perform actions.

## Mount the auth method
Navigate to the Vault UI>Access and enable a new approle authorization. Just leave the name as approle.

## Create the policy
Navigate to the Vault UI>Policies and create an _application_ policy with the following permissions.
```
path "auth/approle/role/application/role-id" {
  capabilities = ["read"]
}

path "auth/approle/role/application/secret-id" {
  capabilities = ["update"]
}

path "auth/approle/login" {
  capabilities = [ "create", "read"]
}

path "application/" {
  capabilities = ["list"]
}

path "application/*" {
  capabilities = ["read"]
}
```
The pattern of authorizing with AppRole should be familiar to GCP and K8s. Each authorization method has slight differences however. In the case of AppRole, the process includes fetching a role id, then generating a secret id to login. You can see we've enabled this policy to explicitly get the role id and secret id for the application path nested under approle auth.

## Create application secret path and secrets
Navigate to the Vault UI>Secrets and mount a new k/v secret engine path _application_. Create the operations path and some secrets with whatever keys and values you want.

## Create the AppRole
SSH into your primary vault cluster and create the approle for _application_.
```
vault write auth/approle/role/application policies="application" secret_id_ttl=5m token_ttl=10m
```
Notice, just like we've done previously for GCP and K8s, we are mapping this role to a policy for access to underlying secrets and operations. We've also set parameters on how long the underlying token that is generated is valid, as well as how long the secret id is valid.

## Create the application token
Create the token so that the application AppRole can be leveraged.
```
vault token create -policy=application -ttl=5m
```

## Use the token to login from another system
Use the scripts provided in this directory to do this as it will greatly ease your effort. Don't forget to set your $VAULT_ADDR to the primary cluster.
```
export VAULT_ADDR=primaryClusterAddy
```
After you've succeeded in retrieving secrets, try using different role paths, or setting shorter ttls on the tokens and think about how the ttl model makes this mapping more secure.
