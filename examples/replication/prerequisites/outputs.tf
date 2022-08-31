output "vpc_id_eu" {
  description = "The identifier of the VCP."
  value       = aws_vpc.default_eu.id
}

output "private_subnet_ids_eu" {
  description = "The created private subnet identifiers."
  value       = aws_subnet.private_eu.*.id
}

output "public_subnet_ids_eu" {
  description = "The created public subnet identifiers."
  value       = aws_subnet.public_eu.*.id
}

output "aws_kms_key_id_eu" {
  description = "The AWS KMS key identifier."
  value       = aws_kms_key.default_eu.id
}

output "vpc_id_us" {
  description = "The identifier of the VCP."
  value       = aws_vpc.default_us.id
}

output "private_subnet_ids_us" {
  description = "The created private subnet identifiers."
  value       = aws_subnet.private_us.*.id
}

output "public_subnet_ids_us" {
  description = "The created public subnet identifiers."
  value       = aws_subnet.public_us.*.id
}

output "aws_kms_key_id_us" {
  description = "The AWS KMS key identifier."
  value       = aws_kms_key.default_us.id
}