# MyKey scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags.

This cluster uses a AWS KMS key that is not generated in the module, but outside of the module. This allows the AWS KMS key to survive a `terraform destroy`, and enables you to restore data because the same encryption and decryption key is used.

```shell
cd network
terraform apply
```

You'll see the subnets created printed as output. These subnets needs to be pasted in `examples/mysubnet/main.yml` under module.vault.subnet_ids.

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
