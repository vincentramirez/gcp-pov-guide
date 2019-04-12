# 6: Okta Authorization
Continuing on with our exploration of authorization.

## Policies
```
path "pci/*" {
  capabilities = ["list"]
}

path "pci/VP" {
  capabilities = ["read"]
}

path "pci/minion" {
  capabilities = ["read", "update"]
}
```

## Initialization
```
vault auth enable okta (UI)
```

```
vault write auth/okta/config \
      base_url="okta.com" \
      organization="candystripegrenade" \
      token="00Af29cQDQoPxtar1cb9dbqfQUX3GiYXThB3T44H5i"
```

```
vault write auth/okta/groups/Everyone policies=pci
```

```
vault login -method=okta username="joshua@candystripegrenade.com"
```
