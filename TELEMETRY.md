# Telemetry

You can enable telemetry in Vault by setting the variable `vault_enable_telemetry` to `true`.

Enabling this has a couple of effects:

- The `vault.hcl` is changed to include telemetry stanza.
- The health check on the target group only allows leader to be healthy.
- The auto-scale-group bases the health of instances on "EC2", which is a check based on a script.

These limitation are required, because only the leader can be used to request telemetry data on.

Vault has a policy that prevents unauthenticated access to "/v1/sys/metrics". Setting `vault_enable_telemetry_unauthenticated_metrics_access` to `true`, allows anybody to access metrics on any Vault node. The side-effect is that any node will be used in the load balancing configuration, and ELB health checks can be used for the auto-scaling group.

## Heath endpoint

The vault health endpoint will return these values under these conditions:

- "200": Raft leaders should not be replaced.
- "429": Raft standby nodes should not be replaced.
- "472": Nodes of Disaster recovery cluster should not be replaced.
- "473": Nodes of Performance replication cluster should not be replaced.

See [documentation on the health endpoint](https://www.vaultproject.io/api-docs/system/health).

## Load balancing considerations

TL;DR: Try to use ELB checks, but fail back to EC2 if that's not possible.

With `vault_enable_telemetry` on, there are some limitations. Telemetry can only be served from the leader, unless `vault_enable_telemetry_unauthenticated_metrics_access` is on, in that case both leader and follower will serve telemetry data.

This table explains the different settings and its effects.

| telemetry | telemetry_unauthenticated_metrics_access | vault nodes |
|-----------|------------------------------------------|-------------|
| true      | true                                     | any         |
| true      | false                                    | leader only |
| false     | false                                    | any         |
| false     | true                                     | any         |

Having `any` or `leader only` has an effect on the auto scaling group:

- `ELB` or `EC2` health checks are used to determine what nodes are healthy.

ELB health checks are preferred, because they reflect the health of the application. EC2 health checks do not consider how an application is running, just the health of the instance.

## Testing

```shell
curl -k -H "X-Vault-Token: ${VAULT_TOKEN}" https://FQDN:8200/v1/sys/metrics
```
