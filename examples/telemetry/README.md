# Telemetry scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags.

With telemetry enabled, the health checks are different, see `TELEMETRY.md`.

## Overview

```text
+--- Vault ---+                +--- Prometheus ---+
|             | <- :8200/tcp - |                  |
+-------------+                +------------------+
                                      ^
                                      |
                                    :9090/tcp
                                      |
      \o/                      +--- Grafana ---+
       | -------> :3000/tcp -> |               |
      / \                      +---------------+
```

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

This will deploy all resources. The Prometheus installation needs access to Vault. You could use the root-key for that, but that's only known after initializing Vault. For this reason, you need to run Terraform twice:

1. Spin up all resources, initialize Vault.
2. Place a token (root-key) in `prometheus.tf`, under the "credential".
3. Run `terraform apply` again.

## Testing

```shell
curl -H "X-Vault-Token: YOUR_TOKEN" https://telemetry.meinit.nl:8200/v1/sys/metrics?format=prometheus
```

### Status in the lifecycle of Vault

When `vault_enable_telemetry_unauthenticated_metrics_access` is `false` (default):

| Stage                         | Comment                                     |
|-------------------------------|---------------------------------------------|
| Before `vault operator init`. | All nodes unhealthy.                        |
| After `vault operator init`.  | Leader of each cluster healthy.             |

When `vault_enable_telemetry_unauthenticated_metrics_access` is `true`:

| Stage                         | Comment                                     |
|-------------------------------|---------------------------------------------|
| Before `vault operator init`. | All nodes unhealthy.                        |
| After `vault operator init`.  | All nodes healthy.                          |

Changing `vault_enable_telemetry_unauthenticated_metrics_access` from `false` (default) to `true` has this effect:

1. The healthcheck changes from `EC2` to `ELB`.
2. The targetgroup matcher adds `429` as an acceptable state.

### Interesting items

[Stolen](https://www.datadoghq.com/blog/monitor-vault-metrics-and-logs/).

| Metric                           | Description                                                | Threshold    |
|----------------------------------|------------------------------------------------------------|--------------|
| vault.core.handle_request        | Number of request handled by Vault core.                   | baseline     |
| vault.raft.(get/put/list/delete) | Duration of an operation against the storage backend (ms)  | baseline     |
| vault.wal.flushready             | Time taken to flush a ready WAL to the persist queue (ms)  | 500ms        |
| vault.wal.persistWALs            | Time taken to persist a WAL to the storage backend (ms)    | 1000 ms      |
| vault.core.handle_login_request  | Time taken by the Vault core to handle login requests (ms) | baseline     |
