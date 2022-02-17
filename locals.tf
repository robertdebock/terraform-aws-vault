locals {
  # A map from `size` to `instance_type`.
  _instance_type = {
    custom      = var.instance_type
    development = "t3.micro"
    minimum     = "m5.large"
    small       = "m5.xlarge"
    large       = "m5.2xlarge"
    maximum     = "m5.4xlarge"
  }
  instance_type = local._instance_type[var.size]

  # A map from `size` to `volume_type`.
  _volume_type = {
    custom      = var.volume_type
    development = "gp2"
    minimum     = "io1"
    small       = "io1"
    large       = "io1"
    maximum     = "io1"
  }
  volume_type = local._volume_type[var.size]

  # A map from `size` to `volume_size`.
  _volume_size = {
    custom      = var.volume_size
    development = 8
    minimum     = 100
    small       = 100
    large       = 200
    maximum     = 200
  }
  volume_size = local._volume_size[var.size]

  # A map from `size` to `volume_iops`.
  _volume_iops = {
    custom      = var.volume_iops
    development = 0
    minimum     = 3000
    small       = 3000
    large       = 10000
    maximum     = 10000
  }
  volume_iops = local._volume_iops[var.size]

  # Resolve the key, either set using `key_name` or place using `key_filename`.
  key_name = try(aws_key_pair.default[0].id, var.key_name)

  # Form the cidr_block based on a variable.
  cidr_block = "${var.aws_vpc_cidr_block_start}.0.0/16"

  # Set the `local.vpc_id` based on either the resource object or the variable object, whichever is available.
  vpc_id = try(aws_vpc.default[0].id, var.vpc_id)

  # Set the `local.internet_gateway_id` based on either the resource object or the data object, whichever is set.
  internet_gateway_id = try(aws_internet_gateway.default[0].id, data.aws_internet_gateway.default[0].id)

  # Set the `local.aws_route_table_id` based on either the resource object or the data object, whichever is set.
  aws_route_table_id = try(aws_route_table.default[0].id, data.aws_route_tables.default[0].id)

  # Set the `aws_subnet_ids` based on either the resource object or the data object, whichever is set.
  aws_subnet_ids = coalescelist(aws_subnet.default[*].id, try(tolist(data.aws_subnets.default[0].ids), []))

}
