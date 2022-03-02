# Network

An overview of the network design.

## API

The API is exposed using a application loadbalancer. Both the API and UI are exposed using the below diagram.

```text
+----------+ :8200/tcp   +---------------+ :8200/tcp   +--------------+
| INTERNET | ----------> | loadbalancer  | ----------> | target_group |
+----------+             | (application) |             +--+-----------+
                         +--+------------+                | :8200/tcp
                            |                             |
                         +--+----------+              +---+-------+
                         | certificate |              | instances |
                         +-------------+              +-----------+
```

## Replication

For enterprise Vault installations, replication can be used to configure "DR" (Disaster Recovery) or "PR" (Performance Replication).

```text
    +---------------------------------------------+
    | :8201/tcp                                   |
    V                                             |
+--+-----------+ :8201/tcp   +--------------+  +--+--------+
| loadbalancer +-----------> | target_group |  | instances |
| (network)    |             +--+-----------+  +--+--------+
+--------------+                | :8201/tcp       |
                              +-+---------+    +--+-----------+ :8201/tcp    +--------------+
                              | instances |    | target_group | <----------+ | loadbalancer |
                              +--+--------+    +--------------+              +--+-----------+
                                 |                                              ^
                                 |                                    :8201/tcp |
                                 +----------------------------------------------+
```
