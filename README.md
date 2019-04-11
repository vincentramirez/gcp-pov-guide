# The POC Guide Book
This repo is a compilation of chapters aligned to organizational value. The workflow for using this repo is to provision the environment, then move immediately into Chapter 1. Although you can skip around the chapters, by design, you will solidify understanding if you progress sequentially.

Included is a [terraform](https://www.terraform.io/) configuration file that can be used to spin up the environment. Make sure you consult the necessary prerequisites before you provision your environment.

## BEFORE RUNNING
The included terraform config uses [KMS](https://cloud.google.com/kms/), [Service Accounts](https://cloud.google.com/compute/docs/access/service-account), & [remote storage](https://www.terraform.io/docs/providers/terraform/d/remote_state.html) in GCP. You can read about the particulars of the remoteStorage in the ./remoteStorage.tf file. You may want to consult the [GCP bucket resource](https://www.terraform.io/docs/providers/google/r/storage_bucket.html) for clarification.

For simplicity sake, you can create a global KMS keyring and key, as well as a global service account from the Google Console. You can use terraform to create these resources as well, but would need to add the associated \*.tf files. Consult [terraform documentation](https://www.terraform.io/docs/providers/google/index.html) for examples on kms keyring, crypt_key, & service account resources.

## STEPS
- make whatever particular changes to your environment via the \*.tf files
- terraform init
- terraform plan
- terraform apply

You will need to pass in variables that terraform has to apply at runtime. Most are strings and are simple "answer" responses to prompts after running terraform plan/apply. However, in the case of serviceAccount, the passed in value is a map with 2 keys: email & scopes. Here is an example:

```
serviceAccount:
{ email = "someServiceAccount" scopes = "cloud-platform" }
```

For using this book, I would stick with the cloud-platform scope. Just know you wouldn't do this in production.

## AFTER
Assuming all went well, you can now start with Chapter 1 & begin your journey. If you encounter any issues, please file an issue in this repo and I'll be sure to address it. Enjoy reading!
