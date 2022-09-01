output "vault_url" {
  description = "The URL to this Vault installation."
  value       = "https://${cloudflare_record.default.hostname}:8200/ui/"
}

output "instructions" {
  description = "How to initialize Vault."
  value       = module.vault.instructions
}