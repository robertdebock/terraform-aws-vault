# Auto snapshot scenario for Vault

Spin up a HashiCorp Vault cluster that automatically unseals and members joins based on AWS tags. Because the Terraform variable `vault_aws_s3_snapshots_bucket` is set, extra policies are applied to the instances, allowing the Vault instances to write to AWS S3 without setting the `aws_access_key_id` or `aws_secret_access_key`.

The directory `configure_autosnapshot` contains code that can be applied after Vault is initialized. The configuration in there configures Vault to store snapshots to S3 periodically.

To actually setup autosnapshots, you can apply a terraform code as such:

```hcl
data "aws_region" "current" {}

resource "vault_raft_snapshot_agent_config" "s3_backups" {
  name             = "s3"
  interval_seconds = 86400 # 24h
  retain           = 7
  path_prefix      = "/path/in/bucket"
  storage_type     = "aws-s3"

  # Storage Type Configuration
  aws_s3_bucket         = "vault-snapshots"
  aws_s3_region         = data.aws_region.current.name
  aws_s3_enable_kms     = true
}
```

The above code is not a part of this module or example, because Vault needs to be initialized, which is not a feature of this module.

## Setup

Download all terraform material.

```shell
terraform init
```

Create an ssh keypair.

```shell
test -f id_rsa.pub || ssh-keygen -f id_rsa
```

Generate a CA key and certificate.

```shell
./vault-tls.sh
```

## Deploying

```shell
terraform apply
```
