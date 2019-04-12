# Chapter 9: Introduction Ops
We've talked a considerable amount about tokens. The primary concern for most automated processes, applications, and services is how they get the initial token used to login. We demonstrated with GCP auth that, if you have a jwt token configured for a service account, you don't need anything other than the role you are trying to login with to get a token to use. However, this isn't always going to be the case.

Vault is flexible to allow for multiple workflows that suit many different use cases. In the cases where an auth method from a trusted provider cannot be used, or in any general case where we want to introduce some token to an end system, we need to do so in the most secure way possible.

To this end, we have 2 options: [Vault Agent](https://www.vaultproject.io/docs/agent/) & response wrapping. I've linked Vault Agent for further inspection by you and your team, but want to spend my time today with response wrapping.

Since we've already familiarized ourselves with AppRole, I think it's an excellent use case for response wrapping. We hopefully remember that AppRole's generic auth mechanism allows for logging in with a role and secret id. Unlike GCP and K8s however, appRole needs a token that allows it to get the roleId and secretId to complete the login process. In the case where appRole is used by some automated thing, it will need a token that allows it to access the vault endpoints to generate the token used to get secrets.

This top level token is a wrapped response. Anything I wrap (tokens, payloads, secrets, etc) will always be assigned a single token that is substituted for the `X-Vault-Token` in a subsequent request to uncover what lies beneath. Wrapped tokens are accessible to anyone, but they are inspectable, single use, and maintain separate ttls from the data they abstract from the possessor.  

This is important to know before one goes about sending tokens across the network.

## SCP
Speaking of network broadcasts. Let's configure an ssh key for our primary vault machine to communicate with our database server. We will store the key in the authorized_keys files of the database server so that we can transfer files (which are just going to be text files) of wrapped tokens for our database server to leverage to get the wrapped responses.

From the primary vault machine:
```
ssh-keygen -t rsa -C "youremail@address"
```
Agree to all the defaults, do not establish passwords. Print the public key to stdout.
```
cat /home/userName/.ssh/id_rsa.pub
```
Then copy & paste it into the database server authorized_keys file at the `/home/userName/.ssh/authorized_keys` path. Now we can do some wrap operations.

## Create a role and map it to the policy
We've already established our _application_ policy. All we need to do is create the token.
```
vault token create -policy=application -ttl=10m -wrap-ttl=5m
```
You'll get a similar, albeit different payload as a response. Let's take a moment to think about what we've done here. Notice the ttl value for the application token I generate is 10 minutes; the wrapped token that we have in the response is only for 5m. That's two different lifecycles: one to access & one to use.

## Send the token to the end system
Copy the token and write it to a tmp file, then scp it to the database server.
```
echo theWrappedToken >> tmp && \
scp tmp userName@ipOrNameOfDBVM:/home/userName/
```

## Unwrap the token, then login with appRole, then get the secrets you need
From the database server, use the tmp file to unwrap the underlying application token.
```
curl -X POST -H "X_VAULT_TOKEN: $(cat /home/userName/tmp)" http://vaultIP:8200/v1/sys/wrapping/unwrap
```
Go ahead and make the call again, it will fail; this is because wrapped tokens are only usable one time.

Use the appRole token you received in the valid unwrapping operation to login, then retrieve secrets. Consult chapter 5 for scripts or references to calls.
