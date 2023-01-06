# Cloudwatch scenario for Vault

Spin up a HashiCorp Vault cluster with AWS Cloudwatch metrics, logs and alarms enabled.

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

## Connecting to the bastion

The Terraform output will show you how to connect to the Bastion host.
