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
  tags = {
    owner = "robertdebock"
  }
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
}

# Add an internet route to the internet gateway.
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a routing table for the nat gateway.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id
}

# Reserve external IP addresses. (It's for the NAT gateways.)
# Skipping this resource because of budget contraints.
# resource "aws_eip" "default" {
#   vpc = true
# }

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.default.names)
  vpc_id            = aws_vpc.default.id
  cidr_block        = "192.168.${count.index + 64}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags = {
    owner = "robertdebock"
  }
}

# Make NAT gateways, for the Vault instances to reach the internet.
# Skipping this resource because of budget contraints.
# resource "aws_nat_gateway" "default" {
#   allocation_id = aws_eip.default.id
#   subnet_id     = aws_subnet.public[count.index].id
#   tags          = local.tags
#   depends_on    = [aws_internet_gateway.default]
# }

# Add an internet route to the nat gateway.
# Skipping this resource because the nat gateway is skipped.
# resource "aws_route" "private" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_internet_gateway.default.id
# }

# Find availability_zones in this region.
data "aws_availability_zones" "default" {
  state = "available"
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "public" {
  count             = length(data.aws_availability_zones.default.names)
  vpc_id            = aws_vpc.default.id
  cidr_block        = "192.168.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags = {
    owner = "robertdebock"
  }
}

# Create extra subnets to mock an environment with multiple subnets.
resource "aws_subnet" "extra" {
  count             = length(data.aws_availability_zones.default.names)
  vpc_id            = aws_vpc.default.id
  cidr_block        = "192.168.${count.index + 192}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags = {
    owner = "robertdebock"
  }
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.default.names)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
