# Target Groups

This deployment creates AWS Target Groups.

## Open Source

When you set `vault_type` to `opensource`, you will get one target group for port `:8200/tcp`. The API and UI can be accessed on this port.

### Expected state

- 3 healthy instance.
- no unhealthy instances.

Basically all nodes receives all the API and UI traffic and the standby nodes forward traffic to the leader.

## Enterprise

When you set `vault_type` to `enterprise`, you will get two target groups:

1. Port `:8200/tcp` - The API and UI can be accessed on this port.
2. Port `:8201/tcp` - Vault replication (cluster to cluster, for DR and PR) can be used.

### Expected state

#### Port :8200/tcp

- 3 healthy instance.

Basically one node receives all the API and UI traffic.

#### Port :8201/tcp

- 3 healthy instances.

Basically any node can be used to setup replication. The load balancer will pick one node.
