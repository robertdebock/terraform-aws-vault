# Enterprise scenario for 2 Vault clusters

Spin up a HashiCorp Vault Enterprise cluster that automatically unseals and members joins based on AWS tags.

More details on [replication](REPLICATION.md).
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
