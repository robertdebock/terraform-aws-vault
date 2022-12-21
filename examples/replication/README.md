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
cd prerequisites
terraform init
terraform apply
cd ../
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

> Note: Remember to set the vault license in `main.tf`

```shell
terraform apply
```

Follow the instructions to initialize the Vault clusters.

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

Because a single bastion host is used for each region, please be aware that you may be logged in to another Vault instance. You may need to set (or unset) the `VAULT_TOKEN` and reset the `VAULT_ADDR` variable.

1. Enable PR primary on vault-eu-0 `vault write -f sys/replication/performance/primary/enable primary_cluster_addr=https://replication-eu-0.${var.domain}:8201`
2. Create a PR token on vault-eu-0: `vault write -f sys/replication/performance/primary/secondary-token id=vault-us-0`
3. Enable PR secondary on vault-us-0: `vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN`.
4. Enable DR primary on vault-eu-0: `vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://replication-eu-0.${var.domain}:8201`.
5. Enable DR primary on vault-us-0: `unset VAULT_TOKEN && vault login -method=userpass username=tester && vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://replication-us-0.${var.domain}:8201`
6. Create a DR token on vault-eu-0: `vault write sys/replication/dr/primary/secondary-token id="vault-eu-1"`
7. Create a DR token on vault-us-0: `vault write sys/replication/dr/primary/secondary-token id="vault-us-1"`
8. Enable DR secondary on vault-eu-1: `vault write sys/replication/dr/secondary/enable token=WRAPPING_TOKEN_FROM_EU_0`
9. Enable DR secondary on vault-us-1: `vault write sys/replication/dr/secondary/enable token=WRAPPING_TOKEN_FROM_US_0`

> NOTE: After enabling secondary replication, the auto-pilot configuration is wiped and needs to be re-applied.

### Status in the lifecycle of Vault PR + DR

| Stage                         | Comment                                     |
|-------------------------------|---------------------------------------------|
| Before `vault operator init`. | All nodes unhealthy.                        |
| After `vault operator init`.  | Leader of each cluster healthy.             |
| After PR setup.               | Leader of each cluster healthy.             |
| After DR setup.               | DR Secondary clusters: all nodes unhealthy. |

> During the setup of DR, the nodes of the DR secondaries will be replaced by the ASG.
### Performance Replication parameters

Both the primary and secondary have parameters when setting up Vault replication. This can be confusing, here is a table and some situations that should clarify the required values for these parameters.

|               | primary_api_addr                               | primary_cluster_addr                                |
|---------------|------------------------------------------------|-----------------------------------------------------|
| Description   | Loadbalancer or node on port 8200              | Loadbalancer or node on port 8201                   |
| Applicable to | sys/replication/performance/secondary/enable   | sys/replication/performance/primary/secondary-token |
| Run on        | Your intended SECONDARY                        | Your intended PRIMARY                               |
| When to set   | When Vault is load balanced, or not resolvable | When Vault is load balanced, or not resolvable      |

Here are a couple of scenarios and their required parameter values.

#### Fully reachable

Situation: Vault clusters can reach each other on both :8200/tcp and :8201/tcp. Resolving hosts is possible from all nodes in both clusters.

```text
+--- Vault primary ---+   +--- Vault secondary ---+
|                     |   |                       |
+---------------------+   +-----------------------+
```

1. Primary: `vault write -f sys/replication/performance/primary/enable
2. Primary: `vault write -f sys/replication/performance/primary/secondary-token id=vault-us-0`
3. Secondary: `vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN`

No specific guidance is required to tell Vault where to find the API or cluster.

#### Resolving issues

Situation: The two Vault clusters can't resolve the hostnames of the other cluster members.

```text
+--- Vault primary ---+   +--- Vault secondary ---+
|                     |   |                       |
+---------------------+   +-----------------------+
            |                        |
            +--- NO DNS RESOLVING ---+
```

1. Primary: `vault write -f sys/replication/performance/primary/enable primary_cluster_addr=https://NODE_IP_ADDR:8201
2. Primary: `vault write -f sys/replication/performance/primary/secondary-token id=vault-us-0`
3. Secondary: `vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN primary_api_addr=http://NODE_IP_ADDR:8200`

The NODE_IP_ADDR is any node on the primary cluster. Port 8200 and 8201 should be reachable from the nodes in the secondary cluster.

#### Behind a load balancer

Situation: If Vault is deployed behind a load balancer, the nodes will not know the address of the load balancer. When the secondary node joins the primary, we have to help Vault by explaining where to reach the primary Vault.

```text
+--- load balancer ---+
|                     |
+---------------------+
           |
           V
+--- Vault primary ---+   +--- Vault secondary ---+
|                     |   |                       |
+---------------------+   +-----------------------+
```

1. Primary: `vault write -f sys/replication/performance/primary/enable`
2. Primary: `vault write -f sys/replication/performance/primary/secondary-token id=vault-us-0`
3. Secondary: `vault write sys/replication/performance/secondary/enable token=WRAPPING_TOKEN primary_api_addr=https://LOAD_BALANCER:8200`

The LOAD_BALANCER is the DNS name or IP address of the load balancer serving the Vault nodes on the primary cluster.
