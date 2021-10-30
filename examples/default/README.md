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

You will see the IP address of the bastion-host, connect to that machine, jump to a Vault machine and initialize Vault.

```shell
ssh-add id_rsa
ssh ec2-user@BASTION_HOST
ssh VAULT_HOST
vault operator init
```
