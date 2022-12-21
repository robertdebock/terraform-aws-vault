# Troubleshooting

You can run into issues, just as we have. Here is a list of issues and their resolution.

## vault: command not found

### Situation 1

You spun up a new Vault cluster using this code and want to run `vault` commands.

### Cause 1

The instances that are started, run `user_data` script that install software. That script did not finish.

### Solution 1

Simply wait for the `user_data` script to finish.

## Error initializing: Put "https://127.0.0.1:8200/v1/sys/init": dial tcp 127.0.0.1:8200: connect: connection refused

### Situation 2

A freshly deployed Vault cluster, you have logged into the bastion host and run `vault` commands.

### Cause 2

You are missing environment variables, because the `user_data` script did not finish before you logged in.

### Solution 2

Log out and back into the bastion host and retry

## 502 Bad Gateway

### Situation 3

If `vault operator init` is run right after deployment, this error may occur:

```text
Error initializing: Error making API request.

URL: PUT https://dflt-api-gsqvhy-1187708727.eu-west-1.elb.amazonaws.com:8200/v1/sys/init
Code: 502. Raw Message:

<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
</body>
</html>
```

### Cause 3

The Vault nodes are not ready to service requests.

### Solution 3

The solution is to wait a minute and retry. It can be the Vault did not start up properly, for example an incorrect license was used.

## Vault is sealed

### Situation 4

This can happen directly after `vault operator init`.

### Cause 4

The loadbalancer has not picked a healthy node, your request ends up on an uninitialized and sealed node.

## Solution 4

The solution is to retry.

## error creating ELBv2 Listener ... UnsupportedCertificate

### Situation 5

When applying Terraform, you may run into this issue. Terraform throws this error.

### Cause 5

The certificate has not been validated. This validation process takes a minute or so.

### Solution 5

The solution is to retry the deployment.

## No raft cluster configuration found
### Situation 6

After `vault operator init`, `vault operator raft list-peers` shows: `No raft cluster configuration found` or `local node not active but active cluster node not found`.

### Cause

Quorum was lost.

#### Solution

Not easy, replace the cluster.
