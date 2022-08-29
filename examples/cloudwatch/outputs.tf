output "vault_url" {
  description = "The URL to this Vault installation."
  value       = "https://${cloudflare_record.default.hostname}:8200/ui/"
}

output "instructions" {
  description = "How to initialize Vault."
  value       = module.vault.instructions
}

data "aws_instances" "asg_instances" {
  instance_state_names = ["running"]
  instance_tags = {
    "aws:autoscaling:groupName" = var.name
  }
}

output "asg_instances" {
  value = "${data.aws_instances.asg_instances.private_ips}"
}