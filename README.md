# HashiCorp Vault on AWS

This code spins up a opensource HashiCorp Vault cluster:

- Spread over availability zones.
- Using automatic unsealing.
- Automatically finding other nodes.
- With a load balancer.
- A bastion host.

## Overview

```text
                 +--- lb --------+
       +-------> | type: network |
       |         +---------------+
       |
       |         +--- lb_target_group ---+
       |   +---> | port: 8200            |  <-----------------------+
       |   |     +-----------------------+                          |
       |   |                                                        |
       |   |    +--- listener ---+   +--- autoscaling_group ---+    |
       +---+--- | port: 8200     |   |                         | ---+
                +----------------+   +-------------------------+
                                                   |
                                                   V      
                                     +--- launch_configuration ---+
                                     |                            |
                                     +----------------------------+
```

These variables can be used.

- `name` - default: `"vault"`.
- `key_filename` - default: `"id_rsa.pub"`.
- `region` - default: `"eu-central-1"`.
- `size` - default: `"small"`.
- `amount` - default: `3`.
- `aws_vpc_cidr_block_start` - default `"172.16"`.
- `tags` - default `{owner = "unset"}`.
- `max_instance_lifetime` - default `86400`. (1 day)
- `launch_configuration_version` - default `1`.

There are some more variables in `variables.tf`.

After spinning up a Vault cluster for the fist time, login to one of the vault cluster members and initialize Vault:

```
vault operator init
```

This generates recovery tokens and a root key, keep them safe and secure.

You can turn on auto-cleanup of dead raft peers:

```shell
vault login ROOT_TOKEN
vault operator raft autopilot set-config \
  -min-quorum=3 \
  -cleanup-dead-servers=true
```

## name

The `name` is used in nearly any resource.

Changes to the `name` cause the current cluster to be destroyed and a new cluster to be deployed.

## vault_version

This determines the version of Vault to install. Pick a version from [this](https://releases.hashicorp.com/vault/) list.

When changing this value, please also change the `launch_configuration_version`.

## size

The `size` variable makes is a little simpler to pick a size for the Vault cluster. For example `small` is the smallest size as recommended in the HashiCorp Vault reference architecture.

Changing this value after the cluster has been deployed has effect after:

- The `max_instance_lifetime` has passed and a instance is replaced.
- Manually triggering an instance refresh in the AWS console.

Replacing instances will keep old Vault peers. (`vault opertator raft list-peers`.)

The `size`: `development` should be considered non-production:

- It's smaller than the HashiCorp Vault reference architecture recommends.
- It's using spot instances, which may be destroyed on price increases.

## amount

The `amount` of machines that make up the cluster can be changed, but there are some considerations:

- If the amount increases from a number lower than the amount of availability zones (typically: `3`); a new load balancer will be created, because new subnets will be created and mapped to the load balancer. The table below tries to explain the behaviour for different scenarios.

| Original value | New value    | Result                |
|----------------|--------------|-----------------------|
| `1`            | `3` and up   | New load balancer.    |
| `3` and up     | `5` and up   | No new load balancer. |
| `3`            | `1`          | New load balancer.    |
| `5`            | `3`          | No new load balancer. |

As a general advice:

- Use a minimum of `3` and a maximum of `5`.
- Going down results in dead peers. (`vault opertator raft list-peers`.) Remove them by logging into a Vault instance and running `vault operator raft remove-peer PEER_TO_REMOVE`.

## max_instance_lifetime

Instance of the autoscale group will be destroyed and recreated after this value in seconds. This ensures you are using a "new" instance every time and you are not required to patch the instances, they will be recreated instead with the most recent image.

## launch_configuration_version

Because the launch configuration can't be overwritten, this version is used in the `name` to allow creating an extra launch configuration. Every time you change something to the launch configuration, change this number.

Changes requiring a version bump:

- modifications to `user_data.sh.tpl` (which end up in changes to `user_data.sh`).
- `size` changes.
- `vault_version` changes.
- `key_filename` changes.
- `key_filename` changes.

 Note; you can go up (`1` -> `2`) or down (`23` -> `7`), either way, a new launch configuration will be created.

## Backup & restore

To create a backup, log in to a Vault node, use `vault login` and run:

```shell
vault operator raft snapshot save /vault/data/raft/snapshots/raft-$(date +'%d-%m-%Y-%H:%M').snap
```

To restore a snapshot, run:

```shell
vault operator raft snapshot restore FILE
```

## Cost

To understand the cost for this service, you can use cost.modules.tf:

```shell
terraform apply
terraform state pull | curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/
```
