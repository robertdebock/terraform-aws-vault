output "vault_url" {
  description = "The URL to this Vault installation."
  value       = "https://${cloudflare_record.default.hostname}/ui/"
}

output "instructions" {
  description = "How to initialize Vault."
  value       = module.vault.instructions
}
