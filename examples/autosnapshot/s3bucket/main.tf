provider "aws" {
  region = "eu-west-1"
}

# Add some randomness, because S3 bucket names need to be unique.
resource "random_string" "default" {
  length  = 6
  numeric = false
  special = false
  upper   = false
}

# Create an S3 bucket.
resource "aws_s3_bucket" "default" {
  bucket = "vault-snapshots-${random_string.default.result}"
}

resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.default.id
  acl    = "private"
}


output "vault_aws_s3_snapshots_bucket" {
  description = "The bucket that can be used to store snapshots."
  value       = aws_s3_bucket.default.bucket
}