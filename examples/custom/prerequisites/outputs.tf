output "vault_custom_script_s3_url" {
  value = "s3://${aws_s3_bucket.default.bucket}/${aws_s3_object.vault.key}"
}

output "custom_script_s3_bucket_arn" {
  value = aws_s3_bucket.default.arn
}

output "vault_bastion_custom_script_s3_url" {
  value = "s3://${aws_s3_bucket.default.bucket}/${aws_s3_object.bastion.key}"
}

# Show an empty list of security group ids. These security groups can be created, but many more resources
# would need to be created, like vpc, subnet, route_tables, nat_gateways and so on.
output "security_group_ids" {
  value = []
}

output "vpc_id" {
  description = "The identifier of the VCP."
  value       = aws_vpc.default.id
}

output "private_subnet_ids" {
  description = "The created private subnet identifiers."
  value       = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  description = "The created public subnet identifiers."
  value       = aws_subnet.public.*.id
}
