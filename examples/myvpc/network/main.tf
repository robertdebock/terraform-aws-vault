# Create a VCP.
resource "aws_vpc" "default" {
  cidr_block = "192.168.0.0/16"
  tags = {
    owner = "robertdebock"
  }
}

# Create an internet gateway.
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags   = {
    owner = "robertdebock"
  }
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id
}

# Add an internet route to the internet gateway.
resource "aws_route" "default" {
  route_table_id         = aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Find availability_zones in this region.
data "aws_availability_zones" "default" {
  state = "available"
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "default" {
  count             = length(data.aws_availability_zones.default.names)
  vpc_id            = aws_vpc.default.id
  cidr_block        = "192.168.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags = {
    owner = "robertdebock"
  }
}

# resource "aws_subnet" "default" {
#   count             = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
#   vpc_id            = local.vpc_id
#   cidr_block        = "${var.aws_vpc_cidr_block_start}.${count.index}.0/24"
#   availability_zone = data.aws_availability_zones.default.names[count.index]
#   tags              = var.tags
# }

# Associate the subnet to the routing table.
resource "aws_route_table_association" "default" {
  count          = length(data.aws_availability_zones.default.names)
  subnet_id      = aws_subnet.default[count.index].id
  route_table_id = aws_route_table.default.id
}
