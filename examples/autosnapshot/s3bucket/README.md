Setup an AWS S3 bucket to store snapshots in.

This code outputs a bucket name, that should be set in:
- ../main.tf, under the module, in `vault_aws_s3_snapshots_bucket`.
- ./configure_autosnapshots/main.tf, under `aws_s3_bucket`.