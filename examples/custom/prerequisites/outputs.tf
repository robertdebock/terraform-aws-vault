output "vault_custom_script_s3_url" {
  value = "s3://${aws_s3_bucket.default.bucket}/${aws_s3_object.default.key}"
}

output "custom_script_s3_bucket_arn" {
  value = aws_s3_bucket.default.arn
}

# Show an empty list of security group ids. These security groups can be created, but many more resources
# would need to be created, like vpc, subnet, route_tables, nat_gateways and so on.
output "security_group_ids" {
  value = []
}
