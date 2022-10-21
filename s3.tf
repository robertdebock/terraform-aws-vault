# Make an S3 bucket to store scripts.
resource "aws_s3_bucket" "default" {
  bucket = "vault-scripts-${random_string.default.result}"
  tags   = local.scripts_tags
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
