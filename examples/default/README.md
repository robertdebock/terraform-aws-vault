# Default scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags.

## Setup

```shell
terraform init
test -f id_rsa.pub || ssh-keygen -f id_rsa
```

## Deploying

```shell
terraform apply
```
