output "vault_url" {
  value = "http://${module.vault.aws_lb_dns_name}:8200/ui"
}

output "bastion_host_ip" {
  value = module.vault.bastion_host_public_ip
}
