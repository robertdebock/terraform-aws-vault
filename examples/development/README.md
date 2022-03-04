# Development scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags on spot instances. Cheap for development, not for production.

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
