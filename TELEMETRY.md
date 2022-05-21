# Telemetry

You can enable telemetry in Vault by setting the variable `telemetry` to `true`.

Enabling this has a couple of effects:

- The `vault.hcl` is changed to include telemetry stanza.
- The health check on the target group only allows leader to be healthy.
- The auto-scale-group bases the health of instances on "EC2", which is a much weaker check.

These limitation are required, because only the leader can be used to request telemetry data on.

Vault has a policy that prevents unauthenticated access to "/v1/sys/metrics". Setting `telemetry_unauthenticated_metrics_access` to `true`, allows anybody to access metrics on any Vault node. The side-effect is that any node will be used in the load balancing configuration, and ELB health checks can be used for the auto-scaling group.

## Testing

```
curl -k -H "X-Vault-Token: ${VAULT_TOKEN}" https://FQDN:8200/v1/sys/metrics
```
