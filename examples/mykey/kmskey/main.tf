# Make a key for unsealing.
resource "aws_kms_key" "default" {
  description = "Vault unseal key - mykye"
  tags = {
    owner = "robertdebock"
  }
}
