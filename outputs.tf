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

output "instructions" {
  description = "How to bootstrap Vault."
  value       = <<EOF
  1. Run: ssh ec2-user@${try(aws_instance.bastion[0].public_ip, "some-host-you-already-have")}
  2. Run: vault operator init
  3. Run: vault login
  4. Run: vault operator raft autopilot set-config -min-quorum=${local.amount} -cleanup-dead-servers=true -dead-server-last-contact-threshold=${var.cooldown / 2.5}
EOF
}

output "aws_lb_replication_dns_name" {
  description = "The DNS name of the replication loadbalancer."
  value       = try(aws_lb.replication[0].dns_name, "No replication loadbalancer has been created.")
}

output "bastion_subnet_id" {
  description = "The subnet of the bastion host."
  value       = try(aws_subnet.bastion[0].id, "no bastion subnet created.")
}

output "vpc_id" {
  description = "The VPC identifier where Vault is deployed."
  value       = local.vpc_id
}
