output "vault_url" {
  description = "The URL to this Vault installation."
  value       = "https://${module.vault.aws_lb_dns_name}:8200/ui"
}

output "instructions" {
  description = "How to initialize Vault."
  value       = module.vault.instructions
}

output "bastion_host_ip" {
  description = "The IP address of the bastion host."
  value       = module.vault.bastion_host_public_ip
}

output "vault_instances" {
  description = "The private addresses of the Vault hosts. You can reach these throught the bastion host."
  value       = module.vault.vault_instances
}
