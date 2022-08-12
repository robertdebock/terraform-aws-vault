# DR-PR scenario for Vault

Spin up a multiple HashiCorp Vault clusters that automatically unseals and members joins based on AWS tags. These Vault clusters can be used to migrate from one Vault environment by setting up Disaster Recovery (DR) and Performance Replication (PR) environments. Be aware that setting up DR or PR is a manual task.

The intent of these clusters is as follows:

```text
+--- vault-0 ---+    MIGRATE   +--- vault-1 ---+              +--- vault-2 ----+
| ORIGINAL      | ---> PR ---> |               | ---> PR ---> |                |
+---------------+              +---------------+              +----------------+
                                      |                              |
                                      V                              V
                                      DR                             DR
                                      |                              |
                                      V                              V
                               +--- vault-3 ---+              +--- vault-4 ----+
                               |               |              |                |
                               +---------------+              +----------------+
```

- "vault-0" is the "original" cluster, where all data lives. We'd like to migrate that data to "vault1".
- "vault-1", "vault-2", "vault-3" and "vault-4" are the target architecture. This is what will remain.
- Once migrated, we'll abandon "vault-0".
- "vault-1" does Performance Replication to "vault-2".
- "vault-1" does Disaster Recovery to "vault-3".
- "vault-2" does Disaster Recovery to "vault-4".

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

## Migrating from "vault-0" to "vault-1"

In this screnario, we'll setup Performance Replication to migrate data from "vault-0" to "vault-1". The "vault-0" cluster will be abondonned.

```text
+--- vault-0 ---+              +--- vault-1 ----+
|               | ---> PR ---> |                |
+---------------+              +----------------+
```

### Create a user

It seems the root token is not valid after the secondary joins the primary. With just the root-key you would be able to setup replication, but you can not login anymore. Creating the following allows the authentication engine to replicate, so you can authenticate on the secondary once connected.

On the intended primary, in this example "vault-0", run:

```shell
vault policy write superuser -<<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
```

```shell
vault auth enable userpass
```

```shell
vault write auth/userpass/users/tester password="changeme" policies="superuser"
```

(You can also do the above steps after the clusters are related.)

### Relate the clusters

On the intendend primary, enable replication as a primary.

```shell
# Tell Vault to become a PR primary and inform Vault of how other clusters should reach raft. (Through the load balancer, which selects the active Vault node.)
vault write -f sys/replication/performance/primary/enable primary_cluster_addr=https://replication-0.robertdebock.nl:8201

# Register a secondary and call it `vault-1`. (You can pick (nearly) any name.)
vault write -f sys/replication/performance/primary/secondary-token id=vault-1
```

Save the `warping_token`.

One the intended secondary.

```shell
vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN
```

After replication is in sync, you can disconnect "vault-0" from "vault-1":

1. Demote "vault-0": `vault write -f sys/replication/dr/primary/demote`.
2. Promote "vault-1": `vault write -f /sys/replication/dr/secondary/promote primary_cluster_addr=https://replication-1.robertdebock.nl:8201`.

Data has now been migrated. 
## Relate (PR) "vault-1" to "vault-2"

Next intent:

```text
    eu-west-1                      us-east-1
+--- vault-1 ---+              +--- vault-2 ----+
|               | ---> PR ---> |                |
+---------------+              +----------------+
```

### On "vault-1"

```shell
vault login -method=userpass username=tester
vault write -f sys/replication/performance/primary/secondary-token id=vault-2
```

Save the `warping_token`.

### On "vault-2"

```shell
vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN
```

## Relate (DR) "vault-1" to "vault-3" and "vault-2" to "vault-4"

Final intent:

```text
    eu-west-1                      us-east-1
+--- vault-1 ---+              +--- vault-2 ----+
|               | ---> PR ---> |                |
+---------------+              +----------------+
       |                              |
       V                              V
       DR                             DR
       |                              |
       V                              V
+--- vault-3 ---+              +--- vault-4 ----+
|               |              |                |
+---------------+              +----------------+
```

### On "vault-1"

```shell
vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://replication-1.robertdebock.nl:8201
vault write sys/replication/dr/primary/secondary-token id="vault-3"
```

### On "vault-3"

```shell
vault write sys/replication/dr/secondary/enable token=WRAPPING_TOKEN
```

### On "vault-2"

```shell
vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://replication-2.robertdebock.nl:8201
vault write sys/replication/dr/primary/secondary-token id="vault-4"
```

### On "vault-4"

```shell
vault write sys/replication/dr/secondary/enable token=WRAPPING_TOKEN
```
