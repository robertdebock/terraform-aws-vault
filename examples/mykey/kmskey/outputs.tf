output "aws_kms_key_id" {
  description = "The AWS KMS key identifier."
  value       = aws_kms_key.default.id
}

output "aws_kms_key_arn" {
  description = "The AWS KMS key aws resource name."
  value       = aws_kms_key.default.arn
}
