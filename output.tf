output "aws_lb_dns_name" {
  description = "The DNS name of the loadbalancer."
  value       = aws_lb.api.dns_name
}

output "aws_lb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)."
  value       = aws_lb.api.zone_id
}

output "bastion_host_public_ip" {
  description = "The IP address of the bastion host."
  value       = try(aws_instance.bastion[0].public_ip, "No bastion host created.")
}

output "vault_instances" {
  description = "The private addresses of the Vault hosts. You can reach these throught the bastion host."
  value       = flatten(data.aws_instances.default[*].private_ips)
}

output "instructions" {
  description = "How to bootstrap Vault."
  value       = <<EOF
  1. Run: ssh ec2-user@${aws_instance.bastion[0].public_ip}
  2. Run: ssh ${flatten(data.aws_instances.default[*].private_ips)[0]}
  3. Run: sudo su -
  4. Run: vault operator init
  5. Run: vault login
  6. Run: vault operator raft autopilot set-config -min-quorum=${var.amount} -cleanup-dead-servers=true -dead-server-last-contact-threshold=${var.cooldown / 2.5}
EOF
}
