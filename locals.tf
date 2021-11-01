locals {
  # A map from `size` to `instance_type`.
  _instance_type = {
    development = "t3.micro"
    minimum     = "m5.large"
    small       = "m5.xlarge"
    large       = "m5.2xlarge"
    maximum     = "m5.4xlarge"
  }
  instance_type = local._instance_type[var.size]

  # Form the cidr_block based on a variable.
  cidr_block = "${var.aws_vpc_cidr_block_start}.0.0/16"

  # Set the `local.vpc_id` based on either the resource object or the data object, whichever is set.
  vpc_id =  try(aws_vpc.default[0].id, data.aws_vpc.default[0].id)

  # Set the `local.internet_gateway_id` based on either the resource object or the data object, whichever is set.
  internet_gateway_id =  try(aws_internet_gateway.default[0].id, data.aws_internet_gateway.default[0].id)

  # Set the `local.aws_route_table_id` based on either the resource object or the data object, whichever is set.
  aws_route_table_id = try(aws_route_table.default[0].id, data.aws_route_table.default[0].id)

}
