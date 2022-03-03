# Replication

To setup Disaster Recovery (DR) or Performance Replication (PR), follow these steps.

1. Get the two clusters up and running. (`terraform apply` and follow the steps to initialise.)
2. Enable replication on the primary cluster.
3. Set the `primary_cluster_address` to the load balancer address of the "replication" load balancer. For example: `https://one-replication-SOME_UNIQUE_STRING.elb.eu-west-1.amazonaws.com:8201`.
4. Add a secondary.
5. Copy the `activation token`.
6. On the secondary cluser, enable replication, select "secondary" and past the `activation token`.

After the relation between the two clusters is created, the target_group of the secondary servers 
