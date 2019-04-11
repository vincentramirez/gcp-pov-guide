# Chapter 4: Kubernetes Auth
Alongside service account and instance authentication, Vault offers the ability to authenticate with the popular orchestration platform K8s as well. Considering GKE is readily available with GCP, then it makes sense to leverage this functionality.

## Setup K8s
Your GKE K8s cluster is already deployed (_thanks terraform_). Assuming you have kubectl already running on your local machine, you can navigate to the the GKE dashboard and copy/paste the command that initializes your local kubectl to point to K8s. You need to start with a service account that k8s will use. So, let's load up the following yaml to kubectl.
```
kubectl create serviceaccount solutions-engineering && \
kubectl apply -f - <<YAML
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: solutions-engineering
  namespace: default
YAML
```

## Setup K8s Auth
Navigate to the Vault UI>Access & enable the kubernetes auth engine. You should use the following output to populate the necessary fields in the UI:
```
export VAULT_SA_NAME=$(kubectl get sa solutions-engineering -o jsonpath="{.secrets[*]['name']}") && \
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo) && \
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
```
- kubernetes_host: From GKE Console, get the K8s host IP
- kubernetes_ca_cert=the output from $SA_CA_CRT
- token_reviewer_jwt=the output from $SA_JWT_TOKEN


## Create a role
Now we need to set up the role. If I were an operator, I would do this from the cli of the primary vault instance. So, ssh into that instance and leverage the following command:
```
vault write auth/kubernetes/role/solutions-engineering \
    bound_service_account_names=solutions-engineering \
    bound_service_account_namespaces=default \
    policies=solutions_engineering \
    ttl=1h
```

## Login and retrieve secrets in a k8s playground
Using a temporary container, we can run some commands from within our k8s environment and get the secrets mapped to our solutions-engineering role.
```
kubectl run tmp --rm -i --tty --serviceaccount=solutions-engineering --image alpine:3.7
```
Once the deprecation warnings go away and the prompt shows up, run the following to update packages, get curl & jq, as well as set environment variables and make a call to Vault.  
```
apk update && \
apk add curl jq && \
VAULT_ADDR=http://theIpOfYourPrimaryVaultInstance:8200 && \
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) && \
curl curl -s $VAULT_ADDR/v1/sys/health | jq
```
Ok...everything is working. You should get some output regarding your Vault instance. Now you need make a request to login and get your access token.
```
curl --request POST \
        --data '{"jwt": "'"$KUBE_TOKEN"'", "role": "solutions-engineering"}' \
        $VAULT_ADDR/v1/auth/kubernetes/login | jq
```
Use the token output to get your secrets.
```
curl -H 'X-Vault-Token: theOutputOfToken' $VAULT_ADDR/v1/solutions_engineering/macys
```
