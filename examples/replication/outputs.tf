output "vault_urls_us" {
  description = "The URL to this Vault installation."
  value       = cloudflare_record.api_us.*.hostname
}

output "vault_urls_eu" {
  description = "The URL to this Vault installation."
  value       = cloudflare_record.api_eu.*.hostname
}

output "instructions_us" {
  description = "How to initialize Vault."
  value       = module.vault_us.*.instructions
}

output "instructions_eu" {
  description = "How to initialize Vault."
  value       = module.vault_eu.*.instructions
}

output "vault_url" {
  description = "The global endpoint, routing to the nearest active Vault cluster."
  value       = "https://vault.my_company.com:8200/"
}