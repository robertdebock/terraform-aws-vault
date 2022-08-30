# Create a VCP.
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags = {
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Create an internet gateway.
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "Vault public"
  }
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
  tags = {
    Name = "Vault private"
  }
}

# Reserve external IP addresses. (It's for the NAT gateways.)
# Skipping, because the NAT gateway is disabled.
# resource "aws_eip" "default" {
#   vpc = true
# }

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.default.names)
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.${count.index + 64}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags = {
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Make NAT gateways, for the Vault instances to reach the internet.
# Skipping this resource because of budget contraints.
# resource "aws_nat_gateway" "default" {
#   allocation_id = aws_eip.default.id
#   subnet_id     = aws_subnet.public[0].id
#   tags = {
#     owner = "robertdebock"
#     purpose = "ci-pr-dr"
#   }
#   depends_on    = [aws_internet_gateway.default]
# }

# Add an internet route to the nat gateway.
# Skipping this, because the NAT gateway is disabled.
# resource "aws_route" "private" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.default.id
# }

# Associate the subnet to the routing table.
resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.default.names)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Find availability_zones in this region.
data "aws_availability_zones" "default" {
  state = "available"
  # The availability zone "us-east-1e" does not have all instance_types available.
  exclude_names = ["us-east-1e"]
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "public" {
  count             = length(data.aws_availability_zones.default.names)
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags = {
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.default.names)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}