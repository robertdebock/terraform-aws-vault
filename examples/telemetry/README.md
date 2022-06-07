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

## Testing

```shell
curl -H "X-Vault-Token: YOUR_TOKEN" https://telemetry.robertdebock.nl:8200/v1/sys/metrics?format=prometheus
```

### Interesting items

[Stolen](https://www.datadoghq.com/blog/monitor-vault-metrics-and-logs/).

| Metric                           | Description                                                | Threshold    |
|----------------------------------|------------------------------------------------------------|--------------|
| vault.core.handle_request        | Number of request handled by Vault core.                   | baseline     |
| vault.raft.(get|put|list|delete) | Duration of an operation against the storage backend (ms)  | baseline     |
| vault.wal.flushready             | Time taken to flush a ready WAL to the persist queue (ms)  | 500ms        |
| vault.wal.persistWALs            | Time taken to persist a WAL to the storage backend (ms)    | 1000 ms      |
| vault.core.handle_login_request	 | Time taken by the Vault core to handle login requests (ms) | baseline     |
