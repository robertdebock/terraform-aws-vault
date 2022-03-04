# Upgrading Vault

If you need to upgrade Vault, read [the documentation](https://www.vaultproject.io/docs/upgrading).

And eventually update the variable `vault_version`:

```hcl
module "vault" {
  source  = "robertdebock/vault/aws"
  certificate_arn = aws_acm_certificate.default.arn
  version = "2.4.0"
  vault_version = "1.9.4"
}
```
