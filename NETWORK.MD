# Network

This module can either create all network resources, or use subnets that are already existing.

To create all network resources:

- Don't set `var.vpc_id`.
- Don't set `var.private_subnet_ids`.
- Don't set `var.private_subnet_ids`.

To use existing network resources:

- Set the `var.vpc_id`.
- Set `var.private_subnet_ids` to a subnet with a NAT router.
- Set `var.private_subnet_ids` to a subnet with an internet gateway.
- Optionally set `var.vpc_cidr_block_start` to the first two CIDR octets available in the VPC.

## API and replication

The API port (and optionally the replication port) is/are exposed using a loadbalancer.

```text
                         +---------+
   +--------- :22/tcp -> | bastion | -- :22/tcp -------------------------+
   |                     +---------+                                     |
+----------+ :8200/tcp   +---------------+ :8200/tcp   +--------------+  |
| INTERNET | ----------> | loadbalancer  | ----------> | target_group |  |
+--+-------+ :8201/tcp   +---------------+ :8201/tcp   +--+-----------+  |
   ^                        |                             | :8200/tcp    |
   |                        |                             | :8201/tcp    |
   |                     +--+----------+              +---+-------+      |
   |                     | certificate |              | instances | <----+
   |                     +-------------+              +--+--------+
   |                                                     |
   |                     +-------------+                 |
   +---------------------| nat_gateway |<----------------+
                         +-------------+
```

## Network components

```text
+--- vpc -------------------------------------------+
|                                                   |
|   +--- internet_gateway ----+                     |
|   |                         |                     |
|   +-------------------------+                     |
|                                                   |
|   +--- subnet: public --------+                   |
|   |   +--- nat_gateway ---+   |   +--- eip ---+   |
|   |   |                   |---|-->|           |   |
|   |   +-------------------+   |   +-----------+   |
|   +---------------------------+                   |
|                                                   |
|   +--- subnet: private ---+                       |
|   |                       |+                      |
|   |                       ||+                     |
|   +-----------------------+||                     |
|    +-----------------------+|                     |
|     +-----------------------+                     |
+---------------------------------------------------+
```

## Routing

```text
+--- route_table: public --------------+      +--- subnet: public ---+
| route: 0.0.0.0/0 -> internet_gateway | ---> |                      |
+--------------------------------------+      +----------------------+

+--- route_table: private --------+        +--- subnet: private ---+
| route: 0.0.0.0/0 -> nat_gateway |+ ----> |                       |+
+---------------------------------+|+ ---> +-----------------------+|+
 +---------------------------------+| --->  +-----------------------+|
  +---------------------------------+        +-----------------------+
```
