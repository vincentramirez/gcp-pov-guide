# Chapter 2: Tell Me A Secret
Secrets are arbitrary in any technical system. The only thing that differentiates them from other data is that we deem them sensitive for whatever reason. In the base case, Vault can store any string as an encrypted secret and decrypt it only when requested by an authenticated client.

To authenticate a client, Vault has to know what secrets the client has access to. A policy is a unit of code that represents an identity and the secret file paths it has access to. Let's begin exploring these concepts by creating a policy.

## Create a policy
Navigate to the Vault UI > Policies and create a new policy: _solutions_engineering_:
```
path "solutions_engineering/" {
  capabilities = ["list"]
}

path "solutions_engineering/*" {
  capabilities = ["list", "read"]
}
```
This policy definition provides access to secrets nested in the solutions_engineering path. However, this is just a policy. We need to mount the secret engine that will store the secrets that this policy will authenticate access to.

Navigate to the Vault UI > Secrets and enable a new secret engine. Select k/v and name it _solutions_engineering_ (make sure to set it to version 1). This officially creates a file path where we can store secrets; the policy we wrote in the previous step will control access to these secrets. Create a file path _my_ and then a key _poc_ with any value you want.

## Create the user
We have a policy and associated secret path, now we need to create an identity to use them. SSH into your primary vault cluster:
```
ssh -i ~/.ssh/id_rsa ${yourUser}:${ipAddressOfVaultClientNode}
```
Once at the prompt, set the VAULT_ADDR env variable, login with the token for the cluster, & generate a token associated with the solutions_engineering identity:
```
export VAULT_ADDR=http://localhost:8200 && \
vault login token thePrimaryToken && \
vault token create -policy=solutions_engineering -ttl=30s
```
The last step is the most important in the above code snippet. Notice that we create a token & map it to the _solutions_engineering_ policy we defined earlier via `-policy=solutions_engineering`. The token that is generated is the authentication device for any requesting client. This token represents an identity that has access to any secret nested in the _solutions_engineering_ file path that we mounted in Vault earlier.

## Fail
Let's try to write some secrets with our solutions_engineering path. From your local machine, set the VAULT_ADDR environment variable to one of the nodes in the primary vault cluster. Use curl to request the file path making sure to set the access token generated from the previous step as the `X-Vault-Token` header of the request. You can set any key/value pairs as your data in the respective payload. In doing so, you are asking Vault to let you add secrets to the `solutions_engineering/my` path.
```
export VAULT_ADDR=thePrimaryVaultAddy && \
curl -X POST -H 'X-Vault-Token: yourSEToken' -d '{stuff...}' $VAULT_ADDR/v1/solutions_engineering/my
```
Wait...What? That didn't work because this token does not have permission to write to any file path nested in _solutions_engineering_. Take a look back at the policy we defined earlier. Notice the capabilities are "read" & "list". If I wanted to allow writing, I would need to add "create" to the policy definition where I wanted the identity to be able to add values. For now, move on to what we can do, read the secrets.

## Succeed
Make another request to one of the nodes in the primary Vault cluster making sure to set your `X-Vault-Token` header to the token generated a few steps back. We just want to read, so no payload is required.
```
curl 'X-Vault-Token: yourSEToken' $VAULT_ADDR/v1/solutions_engineering/my
```
Wait...What? You're right; that was supposed to work. However, we set a `-ttl=30s` flag on the token creation command. By the time we messed up in the previous step, the generated token's lease had expired. Repeat the token creation step and add a longer `-ttl` flag, say `-ttl=5m`. Then make the above call for secrets again and get your my poc value.

What is most important here is that we understand the power of short term credentials. Oftentimes, everyone is concerned about rotation of passwords and usernames and such. That's perfectly fine, but Vault's security model is a rotation/request model. You are using a brand new credential every time a request is made; this credential will expire on it's own according to some specified period of time. You can still rotate the underlying secret values at your whim, but knowing that every request yields a new valid identity adds another layer of security to the operating model of your organization.

To learn more about policy writing, reference the [documentation](https://www.vaultproject.io/docs/concepts/policies.html).
