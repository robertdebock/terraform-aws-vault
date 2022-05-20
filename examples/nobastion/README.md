# No bastion host scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags, but without a bastion host. This scenario would be applicable if you want to use this module to deploy Vault to your own VPC.

## Setup

Download all terraform material.

```shell
terraform init
```

Create an ssh keypair.

```shell
test -f id_rsa.pub || ssh-keygen -f id_rsa
```

Generate a CA key and certificate.

```shell
./vault-tls.sh
```

## Deploying

```shell
terraform apply
```
