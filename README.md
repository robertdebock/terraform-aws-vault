# HashiCorp Vault on AWS

This code spins up an opensource HashiCorp Vault cluster:

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
- `vault_version` - default `"1.8.5"`.
- `key_filename` - default: `"id_rsa.pub"`.
- `region` - default: `"eu-central-1"`.
- `size` - default: `"small"`.
- `amount` - default: `3`.
- `bastion_host` - default: `true`.
- `aws_vpc_cidr_block_start` - default `"172.16"`.
- `tags` - default `{owner = "unset"}`.
- `max_instance_lifetime` - default `86400`. (1 day)
- `vpc_id` - default `""`.

## Deployment

After spinning up a Vault cluster for the fist time, login to one of the Vault cluster members and initialize Vault:

```shell
vault operator init
```

This generates recovery tokens and a root key, keep them safe and secure.

You must turn on auto-cleanup of dead raft peers in order to remove dead nodes and keep a majority of the Vault nodes healthy during scaling activities.

```shell
vault login ROOT_TOKEN
vault operator raft autopilot set-config \
  -min-quorum=3 \
  -cleanup-dead-servers=true \
  -dead-server-last-contact-threshold=120
```

The value of `dead-server-last-contact-threshold` has a relation to the `autoscaling_group.default.cooldown` (default: `300`); `dead-server-last-contact-threshold` must be lower than the `autoscaling_group.default.cooldown` period to allow the old node to be removed, so consensus can be achieved.

## Variables

Some more details about the variables below.

### name

The `name` is used in nearly any resource.

You can't change this value after a deployment is done, without loosing service.

### vault_version

This determines the version of Vault to install. Pick a version from [this](https://releases.hashicorp.com/vault/) list. The first Vault version packaged into an RPM was `1.2.7`.

Changing this value after the cluster has been deployed has effect after:

- The `max_instance_lifetime` has passed and a instance is replaced.
- Manually triggering an instance refresh in the AWS console.

### size

The `size` variable makes is a little simpler to pick a size for the Vault cluster. For example `small` is the smallest size as recommended in the HashiCorp Vault reference architecture.

Changing this value after the cluster has been deployed has effect after:

- The `max_instance_lifetime` has passed and a instance is replaced.
- Manually triggering an instance refresh in the AWS console.

The `size`: `development` should be considered non-production:

- It's smaller than the HashiCorp Vault reference architecture recommends.
- It's using spot instances, which may be destroyed on price increases.

### amount

The `amount` of machines that make up the cluster can be changed. Use `3` or `5`.

Changes to the `amount` variable have immediate effect, without refreshing the instances.

### vpc_id

If you have an existing VPC, you can deploy this Vault installation in that VPC by setting this variable. The default is `""`, which means this code will create (and manage) a VPC (and all it's dependencies) for you.

Things that will be deployed when not specifying a VPC:

- `aws_vpc`
- `aws_internet_gateway`
- `aws_route_table`
- `aws_route`
- `aws_subnet`
- `aws_route_table_association`

When you do provide a value for the variable `vpc_id`, it should have:

- A subnet for all availability zones.
- An internet gateway and all routing to the internet setup.

You can't change this value after a deployment is done, without loosing service.

### max_instance_lifetime

Instance of the autoscale group will be destroyed and recreated after this value in seconds. This ensures you are using a "new" instance every time and you are not required to patch the instances, they will be recreated instead with the most recent image.

### bastion_host

You can have this module spin up a bastion host. If you have not set `vpc_id`, or it's set to `vpc_id`; you can only access then instances through a bastion host, so set `bastion_host` to `true`, which is default.

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
