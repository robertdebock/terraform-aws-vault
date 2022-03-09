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
