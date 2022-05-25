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
