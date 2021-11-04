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

  # A map from `size` to `volume_type`.
  _volume_type = {
    development = "gp2"
    minimum     = "io1"
    small       = "io1"
    large       = "io1"
    maximum     = "io1"
  }
  volume_type = local._volume_type[var.size]

  # A map from `size` to `volume_size`.
  _volume_size = {
    development = "8"
    minimum     = "50"
    small       = "50"
    large       = "100"
    maximum     = "100"
  }
  volume_size = local._volume_size[var.size]

  # A map from `size` to `volume_iops`.
  _volume_iops = {
    development = "0"
    minimum     = "2500"
    small       = "2500"
    large       = "5000"
    maximum     = "5000"
  }
  volume_iops = local._volume_iops[var.size]

  # Form the cidr_block based on a variable.
  cidr_block = "${var.aws_vpc_cidr_block_start}.0.0/16"

  # Set the `local.vpc_id` based on either the resource object or the data object, whichever is set.
  vpc_id = try(aws_vpc.default[0].id, data.aws_vpc.default[0].id)

  # Set the `local.internet_gateway_id` based on either the resource object or the data object, whichever is set.
  internet_gateway_id = try(aws_internet_gateway.default[0].id, data.aws_internet_gateway.default[0].id)

  # Set the `local.aws_route_table_id` based on either the resource object or the data object, whichever is set.
  aws_route_table_id = try(aws_route_table.default[0].id, data.aws_route_tables.default[0].id)

  # Set the `aws_subnet_id` based on either the resource object or the data object, whichever is set.
  aws_subnet_ids = try(data.aws_subnet_ids.default[0].id, aws_subnet.default[*].id)
}
