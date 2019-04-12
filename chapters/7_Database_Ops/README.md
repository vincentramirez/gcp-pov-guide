# Chapter 7: Database Ops
We've learned quite a lot. Now it's time to shift our attention away from authentication & toward dynamic secrets. Dynamic secrets are those Vault generates for you so that some operation can be performed. The credential Vault provides can live no longer than you define, so the fear that some outstanding credential is wreaking havoc in your system should go away.

## Initialize the dbs
Database credentials are dynamically generated in Vault. This happens because Vault will maintain a connection to the database with a set of credentials, then clone those credentials according to requests by authorized clients. Once the client has the credentials, they can login to the respective database. We already have a single VM with Cassandra installed. All we have to do is ssh in and start running the service, then check the status of the cluster.
```
ssh -i ~/.ssh/id_rsa userName@ipAddyOfDBVM
sudo service cassandra start
# wait a bit
nodetool status
```

## Enable the database mount engine
Naviate to the Vault UI>Secrets and enable a new engine _database_ (leave the name alone).

## Connect Vault to the database
An operator would set the initial connection to the database. So ssh into the primary vault server and connect Vault to the cassandra database that lives on another VM in our network.
```
ssh -i ~/.ssh/id_rsa userName@ipAddyOfPrimaryVaultVM
vault write database/config/cassy \
plugin_name="cassandra-database-plugin" \
hosts=thePrivateIpOfTheCassandraVM \
protocol_version=4 \
username=cassandra \
password=cassandra \
allowed_roles=cassy
```
You just configured a cassy database path that allows Vault to connect to the cassandra database that lives somewhere else in your network. Any client Vault authorizes can use the cassy role to generate access credentials (username, password) to the cassandra database; the client can use the credentials to login afterwards.

## Create the role for the database connection mapping
Stay where you are and create the cassy role mapping for the cassy database connection.
```
vault write database/roles/cassy \
db_name=cassy \
creation_statements="CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER; \
GRANT SELECT ON ALL KEYSPACES TO {{username}};" \
default_ttl="1h" \
max_ttl="24h"
```
See the template braces in the creation statement. This allows us to see the new user names when we log into the cassandra db with our dynamic credentials. As always, we set a ttl that makes sense, but is never too outlandish because we can create new creds all the time.

## Add database path to a policy
Navigate to the Vault UI>Policies and append the solutions_engineering user with another path:
```
path "database/creds/cassy" {
  capabilities = ["read"]
}
```
Now we can use our solutions engineering token to curl into vault and get credentials to login. Since your ssh connection to the vault primary is still open, go ahead and generate a token with the solutions_engineering policy applied.
```
vault token create -policy=solutions_engineering
```

## Generate credentials
SSH back into the cassandra db vm and then, leveraging your new solutions_engineering token, run the following:
```
curl -H 'X-Vault-Token: newSEToken' http://vaultPrimaryAddy:8200/v1/database/creds/cassy
```
When you get the response back, you will see a dynamically generated username and password. Use these to login to the database:
```
nodetool status && \ # should yield the privateIp
cqlsh privateIp -u dynamicUserName -p dynamicPassword
```
Once logged in, check the entries.
```
LIST USERS;
```

## Kill the root connections
What you've done should make you feel powerful and organized. Leveraging dynamic credentials certainly makes management of secrets much easier. Still, you might be wondering about that initial connection, the one with the cassandra/cassandra username/password combination. Well, you can still log in with it, which isn't really great.

Vault allows you to rotate these connections however. This gives you the ability force database access with only dynamically generated credentials which, if you adopt organized strategies around ttls and key lifecycle, rotation, etc, is an excellent way to wrap up a chunk of users into a few database roles and forget about the security concerns of any credentials outstanding after use.

Simply enough, the rotation aspect is a very simple call to the Vault client, so let's ssh back into the primary.
```
ssh -i ~/.ssh/id_rsa userName@vaultPrimary \
vault write -force database/rotate-root/cassy
```
Now if you try to login to your cassandra database with the cassandra user and password, it won't work. You'll get a permission denied error. If you use any outstanding dynamic credentials, assuming their ttl is still valid, you can access the db. If you generate new credentials, those can access the database too.
