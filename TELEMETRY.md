# Telemetry

You can enable telemetry in Vault.

| `vault_type` | storage engine | telemetry |
|--------------|----------------|-----------|
| `community`  | raft (default) | enabled   |
| `community`  | in-memory      | enabled   |
| `enterprise` | raft (default) | disabled  |
| `enterprise` | in-memory      | enabled   |

Vault has a policy that prevents unauthenticated access to "/v1/sys/metrics". Setting `telemetry_unauthenticated_metrics_access` to `true`, allows anybody to access metrics.
