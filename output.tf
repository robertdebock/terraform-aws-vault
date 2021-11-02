output "aws_lb_dns_name" {
  description = "The DNS name of the loadbalancer."
  value       = aws_lb.default.dns_name
}

output "bastion_host_public_ip" {
  description = "The IP address of the bastion host."
  value       = try(aws_instance.bastion[0].public_ip, "No bastion host created.")
}

output "vault_instances" {
  description = "The private addresses of the Vault hosts. You can reach these throught the bastion host."
  value       = data.aws_instances.default[*].private_ips
}

output "instructions" {
  description = "How to initialize Vault."
  value       = try("For a new deployment, login (ssh ec2-user@${aws_instance.bastion[0].public_ip}), login to a Vault host and run 'vault operator init'.", "Login to a Vault host and run 'vault operator init'.")
}
