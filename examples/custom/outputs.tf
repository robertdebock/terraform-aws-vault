output "vault_url" {
  description = "The URL to this Vault installation."
  value       = "https://${aws_route53_record.default.fqdn}/ui/"
}

output "instructions" {
  description = "How to initialize Vault."
  value       = module.vault.instructions
}

output "bastion_s3_bucket_arn" {
  description = "The AWS S3 arn for storing backups from the Bastion host."
  value       = module.vault.aws_s3_bucket_bastion_arn
}
