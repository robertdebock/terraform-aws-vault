# Configure snapshots in Vault

This code should be applied last, when Vault is up and running. It's here to prove that auto snapshots can be configured.

Theses variables need to be set:

```shell
export VAULT_ADDR="https://some.url:8200"
export VAULT_TOKEN="xyz"
```