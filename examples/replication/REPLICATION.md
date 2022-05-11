# Replication

An extra loadbalancer is created when `vault_replication` is set to `true`.

To setup Disaster Recovery (DR), follow these steps.

1. Get the two clusters up and running. (`terraform apply` and follow the steps to initialise.)
2. Enable (primary) replication on a cluster. `vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://${aws_lb_replication_dns_name_one}:8201` In this example the `aws_lb_replication_dns_name_one` is `replication-one.robertdebock.nl`
3. Add a secondary on the primary cluster. `vault write sys/replication/dr/primary/secondary-token id="two"` (Copy the `wrapping_token` (cli) or `activation token` (ui).)
5. On the other cluster, enable replication, as "secondary" and use the `wrapping_token` or `activation token`. `vault write sys/replication/dr/secondary/enable token="${wrapping_token}"`.

All nodes of the secondary cluster will be replaced because they are sealed and the AWS ASG sees them as unhealthy. After new nodes are started, they are healthy.

More information on setting up DR/PR can be found [here](https://github.com/sharabinth/vault-ha-dr-replica).


eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3NvciI6IiIsImFkZHIiOiJodHRwczovL29uZS5yb2JlcnRkZWJvY2submw6ODIwMCIsImV4cCI6MTY1MjE4OTM2NiwiaWF0IjoxNjUyMTg3NTY2LCJqdGkiOiJodnMuVU05bGdQWFllWlJLWTZTRTJCd1MzMmZWIiwibmJmIjoxNjUyMTg3NTYxLCJ0eXBlIjoid3JhcHBpbmcifQ.Aal5-3FnpSf9hnw9UQzXY1G7FMCOL6ra93EeKCZWf2kj1Ssuswni00TEpOXG8IZ6kCBfiHMSlylUNwWO0DZ7VYOJABXJtnAyghdbFd66kHxMznGw-HmUIxwimsGN04riwxZeoNmbXDMe1R8w82b-znhHmsIa2r7kSWn88ApTwqlaEZ41
