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
vault secrets enable -version=2 kv

my_ipaddress=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
while [ 1 ] ; do
  randomness=$(curl --insecure --header "X-Vault-Token: $(cat ~/.vault-token)" --request POST $(cat .vault-token) -data format=hex https://${my_ipaddress}:8200/v1/sys/tools/random/164)
  vault kv put kv/my-$((1 + $RANDOM % 1042)) my-key=${randomness}
done
```
