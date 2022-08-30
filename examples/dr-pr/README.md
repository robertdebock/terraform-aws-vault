# DR-PR scenario for Vault

Spin up a multiple HashiCorp Vault clusters that automatically unseals and members joins based on AWS tags. These Vault clusters can be used to migrate from one Vault environment by setting up Disaster Recovery (DR) and Performance Replication (PR) environments. Be aware that setting up DR or PR is a manual task.

The intent of these clusters is as follows:

```text
+--- vault-eu-0 ---+              +--- vault-us-0 ----+
|                  | ---> PR ---> |                   |
+------------------+              +-------------------+
        |                                  |
        V                                  V
        DR                                 DR
        |                                 |
        V                                 V
+--- vault-eu-1 ---+              +--- vault-us-1 ----+
|                  |              |                   |
+------------------+              +-------------------+
```

- "vault-eu-0" does Performance Replication to "vault-us-1".
- "vault-eu-0" does Disaster Recovery to "vault-eu-1".
- "vault-us-0" does Disaster Recovery to "vault-us-1".

## Setup

Create all network components in us-east-2 and eu-west-1:

```shell
cd us-east-2
terraform init
terraform apply
cd ../eu-west-1
terraform init
terraform apply
```

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

### Create a user

The root token is not valid once the secondary joins the primary. With just the root-key you would be able to setup replication, but you can not login anymore. Creating the following allows the authentication engine to replicate, so you can authenticate on the secondary once connected.

On the intended primary, in this example "vault-eu-0", run:

```shell
vault policy write superuser -<<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
```

Enable the `userpass` authentication engine.

```shell
vault auth enable userpass
```

Create a user `tester`.

```shell
vault write auth/userpass/users/tester password="changeme" policies="superuser"
```

(You can also do the above steps after the clusters are related.)

### Relate the clusters

1. Enable PR primary on vault-eu-0 `vault write -f sys/replication/performance/primary/enable primary_cluster_addr=https://replication-eu-0.robertdebock.nl:8201`
2. Create a PR token on vault-eu-0: `vault write -f sys/replication/performance/primary/secondary-token id=vault-us-0`
3. Enable PR secondary on vault-us-0: `vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN`.
4. Enable DR primary on vault-eu-0: `vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://replication-eu-0.robertdebock.nl:8201`.
5. Enable DR primary on vault-us-0: `unset VAULT_TOKEN && vault login -method=userpass username=tester && vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://replication-us-0.robertdebock.nl:8201`
6. Create a DR token on vault-eu-0: `vault write sys/replication/dr/primary/secondary-token id="vault-eu-1"`
7. Create a DR token on vault-us-0: `vault write sys/replication/dr/primary/secondary-token id="vault-us-1"`
8. Enable DR secondary on vault-eu-1: `vault write sys/replication/dr/secondary/enable token=WRAPPING_TOKEN`
9. Enable DR secondary on vault-us-1: `vault write sys/replication/dr/secondary/enable token=WRAPPING_TOKEN`