output "vault_urls" {
  description = "The URL to this Vault installation."
  value       = cloudflare_record.api.*.hostname
}

output "instructions" {
  description = "How to initialize Vault."
  value       = module.vault.*.instructions
}
