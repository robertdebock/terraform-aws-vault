# Create a VPC.
resource "aws_vpc" "default" {
  count      = var.vault_aws_vpc_id == "" ? 1 : 0
  cidr_block = var.vault_cidr_block
  tags       = local.vpc_tags
}

# Create an internet gateway if the VPC is not provided.
resource "aws_internet_gateway" "default" {
  count  = var.vault_aws_vpc_id == "" ? 1 : 0
  tags   = local.tags
  vpc_id = local.vpc_id
}

# Find internet gateways if vpc_id was specified.
data "aws_internet_gateway" "default" {
  count = var.vault_aws_vpc_id != "" ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
  lifecycle {
    postcondition {
      condition     = length(self) != 1
      error_message = "No Internet Gateway was found in the VPC."
    }
  }
}

# Reserve external IP addresses. (It's for the NAT gateways.)
resource "aws_eip" "default" {
  count  = var.vault_aws_vpc_id == "" ? length(aws_subnet.public) : 0
  tags   = local.tags
  domain = "vpc"
}

# Make NAT gateways, one for each AZ/subnet. For the Vault instances to reach the internet.
resource "aws_nat_gateway" "default" {
  count         = var.vault_aws_vpc_id == "" ? length(aws_subnet.public) : 0
  allocation_id = aws_eip.default[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = local.tags
  depends_on    = [aws_internet_gateway.default]
}

# Find the NAT gateway if the vpc_id was specified.
data "aws_nat_gateway" "default" {
  count     = var.vault_aws_vpc_id == "" ? 0 : 1
  subnet_id = var.vault_public_subnet_ids[0]
}

# Create routing tables for the Vault instances.
resource "aws_route_table" "private" {
  count  = var.vault_aws_vpc_id == "" ? length(aws_subnet.private) : 0
  tags   = local.private_tags
  vpc_id = local.vpc_id
}

# Add a route to the routing table for the Vault instances.
resource "aws_route" "private" {
  count                  = var.vault_aws_vpc_id == "" ? length(aws_subnet.private) : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default[count.index].id
  route_table_id         = aws_route_table.private[count.index].id
}

# Add a route table to pass traffic from "public" subnets to the internet gateway.
resource "aws_route_table" "public" {
  count  = var.vault_aws_vpc_id == "" ? 1 : 0
  tags   = local.public_tags
  vpc_id = local.vpc_id
}

# Add a route to the internet gateway for the public subnets.
resource "aws_route" "public" {
  count                  = var.vault_aws_vpc_id == "" ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default[0].id
}

# Find availability_zones in this region.
data "aws_availability_zones" "default" {
  state = "available"
  # The availability zone "us-east-1e" does not have all instance_types available.
  exclude_names = ["us-east-1e"]
}

# Create the same amount of (private) subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "private" {
  count             = var.vault_aws_vpc_id == "" ? min(length(data.aws_availability_zones.default.names), local.amount) : 0
  availability_zone = data.aws_availability_zones.default.names[count.index]
  cidr_block        = cidrsubnet(var.vault_cidr_block, 8, count.index)
  tags              = local.private_tags
  vpc_id            = local.vpc_id
}

# Create (public) subnets to allow the loadbalancer to route traffic to intances.
resource "aws_subnet" "public" {
  count             = var.vault_aws_vpc_id == "" ? min(length(data.aws_availability_zones.default.names), local.amount) : 0
  availability_zone = data.aws_availability_zones.default.names[count.index]
  cidr_block        = cidrsubnet(var.vault_cidr_block, 8, count.index + 64)
  tags              = local.public_tags
  vpc_id            = local.vpc_id
}

# Associate the private subnet to the routing table.
resource "aws_route_table_association" "private" {
  count          = var.vault_aws_vpc_id == "" ? min(length(data.aws_availability_zones.default.names), local.amount) : 0
  route_table_id = aws_route_table.private[0].id
  subnet_id      = local.private_subnet_ids[count.index]
}

# Associate the public subnet to the public routing table.
resource "aws_route_table_association" "public" {
  count          = var.vault_aws_vpc_id == "" ? min(length(data.aws_availability_zones.default.names), local.amount) : 0
  route_table_id = aws_route_table.public[0].id
  subnet_id      = aws_subnet.public[count.index].id
}
