# Replication

An extra loadbalancer is created when `cluster_addr` is set.

To setup Disaster Recovery (DR) or Performance Replication (PR), follow these steps.

1. Get the two clusters up and running. (`terraform apply` and follow the steps to initialise.)
2. Enable (primary) replication on a cluster.
3. Add a secondary.
4. Copy the `activation token`.
5. On the other cluster, enable replication, select "secondary" and past the `activation token`.

After the relation between the two clusters is created, the target_group of the secondary servers
