# Create a random string to make tags more unique.
resource "random_string" "default" {
  length  = 6
  numeric = false
  special = false
  upper   = false
}

# Make an S3 bucket to store scripts.
resource "aws_s3_bucket" "default" {
  bucket = "custom-scripts-${random_string.default.result}"
  tags   = {
    Name  = "custom-scripts-${random_string.default.result}"
    owner = "Robert de Bock"
  }
}

# Add the cloudwatch script to the bucket.
resource "aws_s3_object" "default" {
  bucket = aws_s3_bucket.default.id
  etag   = filemd5("./scripts/my_script.sh")
  key    = "my_script.sh"
  source = "${path.module}/scripts/my_script.sh"
}
