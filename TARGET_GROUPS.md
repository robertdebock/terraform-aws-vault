# Target Groups

This deployment creates AWS Target Groups.

## Open Source

When you set `vault_type` to `opensource`, you will get one target group for port `:8200/tcp`. The API and UI can be accessed on this port.

### Expected state

The expected state depends on the configuration of this module.

#### Telemetry disabled

When `telemetry` is set to `false` or `telemetry_unauthenticated_metrics_access` is set to true:

- 3 healthy instance.
- no unhealthy instances.
- Auto scaling group uses the ELB health check.

Basically all nodes receives all the API and UI traffic and the standby nodes forward traffic to the leader.

When `telemetry` is set to `true` and `telemetry_unauthenticated_metrics_access` is set to false:

- 1 healthy instance.
- 2 unhealthy instances.
- Auto scaling group uses the EC2 health check.

## Enterprise

When you set `vault_type` to `enterprise`, you will get two target groups:

1. Port `:8200/tcp` - The API and UI can be accessed on this port.
2. Port `:8201/tcp` - Vault replication (cluster to cluster, for DR and PR) can be used.

### Port :8201/tcp

- 1 healthy instances.
- 2 unhealthy instances.

Basically any node can be used to setup replication. The load balancer will pick one node.
