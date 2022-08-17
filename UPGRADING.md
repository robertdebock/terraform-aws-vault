# Upgrading Vault

If you need to upgrade Vault, read [the documentation](https://www.vaultproject.io/docs/upgrading).

And eventually update the variable `vault_version`:

```hcl
module "vault" {
  source  = "robertdebock/vault/aws"
  certificate_arn = aws_acm_certificate.default.arn
  version = "8.0.1"
  vault_version = "1.11.2"
}
```

## Change the size of the Vault nodes

You can change the `size` of the Vault nodes without losing data. The Scaling Group will replace nodes 1 by 1.

You can also change the `volume_type` on the fly. (This is applicable for `development` sizes.)

## Downtime

There will be no downtime during the changes.
