# Chapter 1: Setup
**NOTE:** _If you are doing this POC, then you already have an enterprise license. You can get one from [here](https://www.hashicorp.com/products/vault/enterprise). This isn't to say that you can't do most of what is in this repo with OSS, but there are features that require an enterprise license to pull off._

## Initialize Vaults
We used terraform to provision 2 clusters (in separate regions) of 8 nodes (5 consul & 3 vault). Consul isn't that important for what we are doing in this POC, so let's focus on the Vault nodes in each cluster.

We've named the vault carrying nodes vault-client-${number} & vault-client-dr-${number} depending on what cluster it's associated with. Although Vault is running on each node, we need to initialize Vault to actually use it. We want to connect our clusters together, so we will need to initialize Vault in each cluster.

First, ssh into 1 of the vault clients in the vault-client-${number} cluster. Run the following command after you've connected:
```
export VAULT_ADDR=http://localhost:8200 && \
vault operator init -key-shares=1 -key-threshold=1 -recovery-shares=1 -recovery-threshold=1
```
Store the returned recovery key and initial root token somewhere in your repo to use later. Something like the following is perfectly fine:
```
VAULT_RECOVERY_KEY=${theRecoveryKeyOutputFromTheAboveCommand}
VAULT_ROOT_TOKEN=${theRootTokenOutputFromTheAboveCommand}
```
 If you look in the .gitignore file, you will see that I've already created some file paths you can leverage that will not be committed to version control. If you use your own files, just please make sure you add the associated file path in the .gitignore file.

 Once you've stored the secretVars for the vault-client-${number} cluster initialization, then you need to repeat the process for the vault-client-dr-${number} cluster. Again, you can choose any 1 of the clients to perform the steps; the important thing is to store the respective outputs in your repo somewhere. Again, maybe something like this:
 ```
 VAULT_DR_RECOVERY_KEY=${theRecoveryKeyOutput}
 VAULT_DR_ROOT_TOKEN=${theRootTokenOutput}
 ```
 Congratulations, you've initialized the vault. You've got 30 minutes to apply the license to each cluster.  

## Apply license
You can use the UI, which is super easy. All you have to do is navigate to url address of **one** of the vault nodes in each cluster (vault-client-\* & vault-client-dr=\*) and click in the top right corner where there should be a dropdown and a license option. Once you've navigated to the license textbox, just copy and paste the license. The key is that you have to do this for **one** of the nodes in each of the clusters you've provisioned; that equates to 2 nodes total.

You can do this with the api too. Just set the VAULT_TOKEN & VAULT_ADDR environment variables on your local machine to the ip url of one of the vault nodes in the vault-client-${number} cluster and then request the license to be applied:  
```
export VAULT_TOKEN=someVaultTokenFromTheFirstStep && \
export VAULT_ADDR=http://xxx.xxx.xx.xx:8200 && \
curl -X PUT -H "X-Vault-Token: $VAULT_TOKEN" -d @license.json $VAULT_ADDR/v1/sys/license &&\
curl -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/license
```
Follow these same steps for one of the nodes in the vault-client-dr-${number} cluster and you're done.

**NOTE 1:** _do not try this with one of the consul nodes. When I say vault-client*-${number}, I mean you need to choose one of the vault nodes to perform these steps._

**NOTE 2:** _if you go about the api workflow, please consult [this](https://learn.hashicorp.com/vault/operations/ops-disaster-recovery) document for specifics on acquiring a dr_operation_token. The license.json file mentioned in the curl command above has 2 keys, the dr_operation_token, which you will need to get via the process defined in the referenced document & text, which should be your license string provided in license.hclic._

## Set up replication **ENTERPRISE ONLY**
For our demo, we will only be configuring DR replication. We would configure PR replication in the same way; the difference is that PR replication gives both clusters the ability to serve read/write requests for secrets. However, our configuration is better suited for a DR strategy, where we want to make sure we keep our secrets in case of failure.

To configure replication, we can use the ui or the api. For simplicity and understanding, we will leverage the ui workflow; however, [this guide](https://learn.hashicorp.com/vault/operations/ops-disaster-recovery) contains every step to configure DR replication from the ui/cli/api. This guide includes how to manage the promotion process in case of failure; I will create this chapter in the future, so for now, just reference the doc if that's something you want to explore.
