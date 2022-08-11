# DR-PR scenario for Vault

Spin up a multiple HashiCorp Vault clusters that automatically unseals and members joins based on AWS tags. These Vault clusters can be used to setup Disaster Recovery (DR) and Performance Replication (PR) environments. Be aware that setting up DR or PR is a manual task.

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

## Setting up replication.

### Performance replication (PR)

In this screnario, we'll setup Performance Replication to copy data from `vault-0` to `vault-1`.

```text
+--- vault-0 ---+              +--- vault-1 ----+
|               | ---> DR ---> |                |
+---------------+              +----------------+
```

On the intendend primary, enable replication as a primary.

```shell
vault write -f sys/replication/performance/primary/enable primary_cluster_addr=https://replication-0.robertdebock.nl:8201
vault write -f sys/replication/performance/primary/secondary-token id=one
```

Save the `warping_token`.

One the intended secondary.

```shell
vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN
```