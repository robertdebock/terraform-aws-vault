# Create a VPC.
resource "aws_vpc" "default" {
  count      = var.vpc_id == "" ? 1 : 0
  cidr_block = local.cidr_block
  tags       = local.tags
}

# Create an internet gateway if the VPC is not provided.
resource "aws_internet_gateway" "default" {
  count  = var.vpc_id == "" ? 1 : 0
  tags   = local.tags
  vpc_id = local.vpc_id
}

# Reserve external IP addresses. (It's for the NAT gateways.)
resource "aws_eip" "default" {
  count = var.vpc_id == "" ? 1 : 0
  tags  = local.tags
  vpc   = true
}

# Make NAT gateways, for the Vault instances to reach the internet.
resource "aws_nat_gateway" "default" {
  count         = var.vpc_id == "" ? 1 : 0
  allocation_id = aws_eip.default[0].id
  subnet_id     = aws_subnet.public[0].id
  tags          = local.tags
  depends_on    = [aws_internet_gateway.default]
}

# Create a routing table for the Vault instances.
resource "aws_route_table" "private" {
  count  = var.vpc_id == "" ? 1 : 0
  tags   = local.private_tags
  vpc_id = local.vpc_id
}

# Add a route to the routing table for the Vault instances.
resource "aws_route" "private" {
  count                  = var.vpc_id == "" ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default[0].id
  route_table_id         = aws_route_table.private[0].id
}

# Add a route table to pass traffic from "public" subnets to the internet gateway.
resource "aws_route_table" "public" {
  count  = var.vpc_id == "" ? 1 : 0
  tags   = local.public_tags
  vpc_id = local.vpc_id
}

# Add a route to the internet gateway for the public subnets.
resource "aws_route" "public" {
  count                  = var.vpc_id == "" ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default[0].id
}

# Find availability_zones in this region.
data "aws_availability_zones" "default" {
  state = "available"
}

# Create the same amount of (private) subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "private" {
  count             = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  availability_zone = data.aws_availability_zones.default.names[count.index]
  cidr_block        = "${var.vpc_cidr_block_start}.${count.index}.0/24"
  tags              = local.private_tags
  vpc_id            = local.vpc_id
}

# # Create (public) subnets to allow the loadbalancer to route traffic to intances.
resource "aws_subnet" "public" {
  count             = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  availability_zone = data.aws_availability_zones.default.names[count.index]
  cidr_block        = "${var.vpc_cidr_block_start}.${count.index + 64}.0/24"
  tags              = local.public_tags
  vpc_id            = local.vpc_id
}

# Associate the private subnet to the routing table.
resource "aws_route_table_association" "private" {
  count          = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  route_table_id = aws_route_table.private[0].id
  subnet_id      = local.private_subnet_ids[count.index]
}

# Associate the public subnet to the public routing table.
resource "aws_route_table_association" "public" {
  count          = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  route_table_id = aws_route_table.public[0].id
  subnet_id      = aws_subnet.public[count.index].id
}
