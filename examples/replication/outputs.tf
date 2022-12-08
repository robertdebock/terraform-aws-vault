output "vault_url_eu_0" {
  description = "value"
  value       = "https://${module.vault_eu[0].aws_lb_replication_dns_name}:8200"
}

output "vault_url_eu_1" {
  description = "value"
  value       = "https://${module.vault_eu[1].aws_lb_replication_dns_name}:8200"
}

output "vault_url_us_0" {
  description = "value"
  value       = "https://${module.vault_us[0].aws_lb_replication_dns_name}:8200"
}

output "vault_url_us_1" {
  description = "value"
  value       = "https://${module.vault_us[1].aws_lb_replication_dns_name}:8200"
}


output "instructions_eu" {
  description = "How to initialize Vault."
  value       = module.vault_eu.*.instructions
}

output "instructions_us" {
  description = "How to initialize Vault."
  value       = module.vault_us.*.instructions
}

output "vault_url_global" {
  description = "The global endpoint, routing to the nearest active Vault cluster."
  value       = "https://${aws_route53_record.global_endpoint_eu.name}:8200/"
}

output "vault_url_eu" {
  description = "The EU endpoint, routing to the active Vault cluster."
  value       = "https://${aws_route53_record.eu[0].name}:8200/"
}

output "vault_url_us" {
  description = "The US endpoint, routing to the active Vault cluster."
  value       = "https://${aws_route53_record.us[0].name}:8200/"
}
