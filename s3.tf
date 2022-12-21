# Make an S3 bucket to store scripts.
resource "aws_s3_bucket" "default" {
  bucket = "vault-scripts-${random_string.default.result}"
  tags   = local.scripts_tags
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.default.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.aws_kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Add the cloudwatch script to the bucket.
resource "aws_s3_object" "cloudwatch" {
  bucket = aws_s3_bucket.default.id
  etag   = filemd5("${path.module}/scripts/cloudwatch.sh")
  key    = "cloudwatch.sh"
  source = "${path.module}/scripts/cloudwatch.sh"
}

# Add the logrotate setup script to the bucket.
resource "aws_s3_object" "logrotate_script" {
  bucket = aws_s3_bucket.default.id
  etag   = filemd5("${path.module}/scripts/setup_logrotate.sh")
  key    = "setup_logrotate.sh"
  source = "${path.module}/scripts/setup_logrotate.sh"
}
