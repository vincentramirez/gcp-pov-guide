# Chapter 3: GCP Authorization
We have service accounts that serve as identities for us in GCP. We may want to map secret access to the service accounts we already use. In this way, GCP serves as an authenticating party for the identities we are already using in our regular business operations.

## Set up GCP Auth
You can use the cli or api for this step, but we've been using the UI, so why not continue to do so in order to solidify understanding. Navigate to the UI>Access>Auth Methods. Enable a new gcp auth method, call it whatever you like on your time, but for this demo, we will leave it as gcp. You will be able to supply it a json file as an upload or text that it will map a role & associated policies to afterwards.

Hopefully you remember the _solutions_engineering_ policy we created in Chapter 1. Our gcp service account will be mapped to this policy, which only has the ability to read secrets at or nested in the solutions_engineering file path in vault. In the wild, an application could log in using this service account to get secrets it needed to manage automated tasks. Use ssh to generate our role for the gcp auth engine from the primary Vault cluster.
```
vault write auth/gcp/role/solutions_engineering \
    type="iam" \
    policies="solutions_engineering" \
    bound_service_accounts="theServiceAccountNameYouUploadedInAPreviousStep"
```
Now that the role is created, we can login to get a token for access to any secrets our service account needs to do it's job.

## Login & get secrets
GCP leverages jwt tokens to sign and authenticate iam accounts. I don't really have time to go over the process of generating a jwt for you to leverage from an api call, so we will be  then use it as a header in a subsequent api call to get our secrets. First, set the necessary environment variables to make the rpc call to the Vault host.
```
export VAULT_TOKEN=tokenOfPrimary && \
export VAULT_IP=ipAddyOfPrimary && \
ssh -i /path/to/your/ssh/id_rsa -t user@$VAULT_IP 'export VAULT_ADDR=http://localhost:8200 && vault login -method=gcp role="solutions_engineering" service_a
ccount="theAccountYouAddedInAPreviousStep" project="yourProject" jwt_exp="15m"'
```
This will output the token the server generated for you. Now all you have to do is use it to get your secrets.
```
export VAULT_ADDR="http://$VAULT_IP" && \
curl -H 'X-Vault-Token: theTokenOutputFromPreviousStep' $VAULT_ADDR/v1/solutions_engineering/my
```
Consult the [docs](https://www.vaultproject.io/docs/auth/gcp.html)/[api](https://www.vaultproject.io/api/auth/gcp/index.html) for more info and detail.
