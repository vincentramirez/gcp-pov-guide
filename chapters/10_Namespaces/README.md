# Chapter 10: Namespaces
With all the access control that policy writing offers, we can actually segment access even further leveraging namespaces. Namespaces may be varying operations or teams on either coast of the domestic US. It may also be business unit and/or team segmentation within the org.

## Configure a namespace
At this point, we have a few policies that we've written. Now, we want to abstract those policies into segmented groups as Namespaces. Begin by navigating to the Vault UI>Access>Namespaces and create a namespace with whatever name you like.

## Update/Create policies
We have the _solutions_engineering_ policy. Now we should abstract this policy into our new Namespace. Just update the policy to include the namespace.
```
path "namespaceYouChose/" {
  capabilities = ["list"]
}

path "namespaceYouChose/solutions_engineering/" {
  capabilities = ["list"]
}

path "namespaceYouChose/solutions_engineering/*" {
  capabilities = ["read"]
}
```
Now if we create a token for _solutions_engineering_ and try to retrieve the secrets that path has access to, we can't. If we retrieve it from the namespace, we can.

## Login with token from namespace
We can also login directly to the namespace from the UI. Using the _solutions_engineering_ token, login to the UI and prepend the namespace you want access to.
