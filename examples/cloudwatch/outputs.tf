output "vault_url" {
  description = "The URL to this Vault installation."
  value       = "https://${aws_route53_record.default.fqdn}:8200/ui/"
}

output "instructions" {
  description = "How to initialize Vault."
  value       = module.vault.instructions
}