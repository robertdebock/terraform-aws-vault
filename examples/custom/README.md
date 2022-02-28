# Custom scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags on specific sized instances.

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

## Testing

You can write "random" data to Vault.

```shell
vault secrets enable -version=2 kv

while [ 1 ] ; do
  randomness=$(curl --insecure --header "X-Vault-Token: $(cat ~/.vault-token)" --request POST --data "format=hex" ${VAULT_ADDR}/v1/sys/tools/random/164)
  vault kv put kv/my-$((1 + $RANDOM % 1042)) my-key=${randomness}
done
```

You can request a bunch of tokens:

```shell
cat << EOF >> payload.json
{
  "meta": {
    "user": "root"
  },
  "ttl": "1h",
  "renewable": true
}
EOF

yum -y install httpd

ab -H "X-Vault-Token: $(cat ~/.vault-token)" -p payload.json -c 16 -n 2014 ${VAULT_ADDR}/v1/auth/token/create
```
