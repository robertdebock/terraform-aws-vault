# Troubleshooting

You can run into issues, just as we have. Here is a list of issues and their resolution.

## `vault: command not found`

If the bastion host does not have the binary `vault` available, log out, wait a moment for `cloud-init` to finish, log back in and retry.

## `Error initializing: Put "https://127.0.0.1:8200/v1/sys/init": dial tcp 127.0.0.1:8200: connect: connection refused`

You are missing environment variables. Log out, log back into the bastion host and retry.

