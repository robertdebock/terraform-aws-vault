output "vault_urls_eu" {
  description = "The URL to this Vault installation."
  value       = aws_route53_record.eu.*.name
}

output "vault_urls_us" {
  description = "The URL to this Vault installation."
  value       = aws_route53_record.us.*.name
}

output "instructions_eu" {
  description = "How to initialize Vault."
  value       = module.vault_eu.*.instructions
}

output "instructions_us" {
  description = "How to initialize Vault."
  value       = module.vault_us.*.instructions
}

output "vault_url" {
  description = "The global endpoint, routing to the nearest active Vault cluster."
  value       = "https://vault.meinit.nl`:8200/"
}