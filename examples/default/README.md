# Default scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags.

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
./vault.tls.sh
```

## Deploying

```shell
terraform apply
```

## Testing

You can write "random" data to Vault.

```shell
while [ 1 ] ; do
  vault kv put kv/my-$((1 + $RANDOM % 1042)) my-key=my-$((1 + $RANDOM % 1024))
done
```
