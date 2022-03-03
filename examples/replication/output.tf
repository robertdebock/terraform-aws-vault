output "vault_url_one" {
  description = "The URL to this Vault installation."
  value       = "https://${cloudflare_record.one.hostname}:8200/ui/"
}

output "vault_url_two" {
  description = "The URL to this Vault installation."
  value       = "https://${cloudflare_record.two.hostname}:8200/ui/"
}

output "instructions_one" {
  description = "How to initialize Vault."
  value       = module.vault_one.instructions
}

output "instructions_two" {
  description = "How to initialize Vault."
  value       = module.vault_two.instructions
}
