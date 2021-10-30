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

  cidr_block = "${var.aws_vpc_cidr_block_start}.0.0/16"
}
