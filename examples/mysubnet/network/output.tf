output "vpc_id" {
  description = "The identifier of the VCP."
  value       = aws_vpc.default.id
}

output "subnet_ids" {
  description = "The created subnet identifiers."
  value       = aws_subnet.extra.*.id
}
