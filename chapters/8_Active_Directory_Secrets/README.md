# Chapter 8: Active Directory Secret Engine
We're continuing our dive into dynamic secrets. The idea is that we want Vault to manage our pre-existing Active Directory users, so that we can generate credentials to access & perform operations on behalf of _Active Directory_ whether onPrem or in a cloud environment.

**NOTE:** _you can skip Setup if you plan to use a pre-existing active directory deployment reachable via some ip address or domain string_

## Setup
We spun up a live environment in chapter 1 using terraform. For this chapter, we will manually add our windows server 2016 instance into our us-east4-a region (dc1). Navigate to Google Cloud Platform > Compute Engine > VMs and click the plus button to add a new VM. The configuration options are as follows:

- machine-type: n1-standard-1
- firewalls: Allow HTTP traffic
- os: windows-cloud/windows-core-2019
- tags: windows, http-server

Once you've spun up your VM, you will want to RDP into it. If you're on a mac, you will have to get the Windows Remote Desktop client application first.

You are going to need a password, & to be honest, I never seem to have any luck with the GCP console to do this correctly; thus my suggestion (and what I will document here) is to use gcloud. From a machine configured correctly with your credentials to gcloud, run the following command:
```
gcloud compute reset-windows-password windows-instance
```  

You will get output similar to this &, for our purposes, enter `Y` when warned about the encryption issues:
```
This command creates an account and sets an initial password for the
user [whateverUserYouAreUsing] if the account does not already exist.
If the account already exists, resetting the password can cause the
LOSS OF ENCRYPTED DATA secured with the current password, including
files and stored passwords.

For more information, see:
https://cloud.google.com/compute/docs/operating-systems/windows#reset

Would you like to set or reset the password for [whateverUserYouAreUsing] (Y/n)?  Y

Resetting and retrieving password for [whateverUserYoAreUsing] on [whateverYouNamedYourInstance]
No zone specified. Using zone [us-east4-a] for instance: [whateverYouNamedYourInstance].
Updated [someUrl].
ip_address: xxx.xxx.xxx.xxx
password:   somePassword
username:   whateverUserYouAreUsing
```
Store that password somewhere you can reference later. It's time to set up AD on our windows vm.

Now navigate back to Google Cloud Console > Compute Engine > VM. Where your windows machine is listed, click on teh **RDP** text to the right of the card and select download RDP file.

Import the RDP connection file into your windows RDP client application and get ready for Active Directory fun.

For a basic Active Directory setup, consult [this guide](https://www.infiflex.com/how-to-setup-active-directory-in-windows-server). When you get to the section regarding resetting the Admin password, make sure you store the credentials in a file so you remember. For convenience, the file path ./secretVars is already in the .gitignore if you want to create that for local use.

**NOTE:** _If you install windows-server-datacenter-2019, then you will have defaults excluding NET 3.5, you can proceed with the AD installation without them; I do not know if this is true for older versions._

**NOTE:** _If you want to configure ssl with ldap(s), then perform the steps in [this guide](https://docs.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/install-the-certification-authority). Make sure you enable a firewall rule in GCP to allow tcp connections on port 636 (for ssl ldap)._

The last piece of the puzzle is setting up a service account with the proper permissions. You can follow most of the steps in [this guide](https://support.passwordboss.com/hc/en-us/articles/360016243831-Creating-a-service-account-to-run-the-Active-Directory-Connector), but make sure that you stop with step 9 of _Creating a service account that is an administrator on the member server._

You should be able to remote into your VM with the now configured AD system whether with your gcp provided user & the new service account you just configured. It's time to connect this service account to Vault and roll that password regularly.

# Configure AD Secret Engine
From your primary vault cluster:
```
ssh -i ~/.ssh/id_rsa userName@ipAddressOfPrimaryVaultInstanceInPrimaryCluster
```

Go through the steps to login and mount the active directory secrets engine:
```
export VAULT_ADDR=http://localhost:8200 &&
vault login rootTokenForPrimaryCluster &&
vault secrets enable ad
```

Next, it's time to establish a connection using the pre-existing service account we either created or you have already managed by Active Directory.
```
vault ad/config \
bindid=ADSERVERDOMAIN\serviceAccountADUser \
bindpass=theServiceAccountUserPassword \
url=ldap://yourADIP \
userdn='dc=theDomainName,dc=theDomainNameExtension & #example='dc=macysexamplead,dc=net' \
ttl=1m \
insecure_tls=true \
starttls=true
```

Next, you want to setup the role that maps your user to the service account string.
```
vault write ad/roles/serviceAccountADUser \
service_account_name="serviceAccountADUser@yourDomainName.yourDomainNameExtension"
```

Now it's time to rotate the root password for the service account user. You can do this because Vault is managing it now.
```
vault read ad/creds/serviceAccountADUser
```

The response is your username, which should look very familiar & a password, which is nothing like you set when you created the service account. Now you can use these credentials to remote into the windows machine you configured active directory with. If you wait for a minute, you can generate the credentials again and notice that you have a brand new password. The password has been rotated & the old credential is no longer valid to use to remote into the machine anymore.

It's important to note that the password rotation of AD is lazy. This means that it won't rotate automatically after the ttl has expired, but that it will the next time it's requested. In our examples here, if you were to stay logged into the server well after a minute, you wouldn't get kicked off, nor would you not be able to log in with it again. The next time you request the credential, the previous credential is invalidated. For automated processes, you would institute an automated workflow that requested new passwords regularly, or have many processes leveraging a single AD account that you rotate all the time via normal job bandwidth.  
