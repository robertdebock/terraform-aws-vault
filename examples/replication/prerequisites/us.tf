# Make a key for unsealing.
resource "aws_kms_key" "default_us" {
  description = "Vault unseal key"
  provider    = aws.us-east-2
  tags = {
    Name  = "replication-us"
    owner = "robertdebock"
  }
}

# Create a VCP.
resource "aws_vpc" "default_us" {
  cidr_block = "10.0.0.0/16"
  provider   = aws.us-east-2
  tags = {
    Name    = "replication-us"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Create an internet gateway.
resource "aws_internet_gateway" "default_us" {
  provider = aws.us-east-2
  vpc_id   = aws_vpc.default_us.id
  tags = {
    Name    = "replication-us"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "public_us" {
  provider = aws.us-east-2
  vpc_id   = aws_vpc.default_us.id
  tags = {
    Name = "replication-us-public"
  }
}

# Add an internet route to the internet gateway.
resource "aws_route" "public_us" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default_us.id
  provider               = aws.us-east-2
  route_table_id         = aws_route_table.public_us.id
}

# Create a routing table for the nat gateway.
resource "aws_route_table" "private_us" {
  provider = aws.us-east-2
  vpc_id   = aws_vpc.default_us.id
  tags = {
    Name = "replication-us-private"
  }
}

# Reserve external IP addresses. (It's for the NAT gateways.)
resource "aws_eip" "default_us" {
  provider = aws.us-east-2
  vpc      = true
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "private_us" {
  count             = length(data.aws_availability_zones.default_us.names)
  availability_zone = data.aws_availability_zones.default_us.names[count.index]
  cidr_block        = "10.0.${count.index + 64}.0/24"
  provider          = aws.us-east-2
  vpc_id            = aws_vpc.default_us.id
  tags = {
    Name    = "replication-us-private"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Make NAT gateways, for the Vault instances to reach the internet.
resource "aws_nat_gateway" "default_us" {
  allocation_id = aws_eip.default_us.id
  provider      = aws.us-east-2
  subnet_id     = aws_subnet.public_us[0].id
  tags = {
    Name    = "replication-us"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
  depends_on = [aws_internet_gateway.default_us]
}

# Add an internet route to the nat gateway.
resource "aws_route" "private_us" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default_us.id
  provider               = aws.us-east-2
  route_table_id         = aws_route_table.private_us.id
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "private_us" {
  count          = length(data.aws_availability_zones.default_us.names)
  provider       = aws.us-east-2
  route_table_id = aws_route_table.private_us.id
  subnet_id      = aws_subnet.private_us[count.index].id
}

# Find availability_zones in this region.
data "aws_availability_zones" "default_us" {
  # The availability zone "us-east-2e" does not have all instance_types available.
  exclude_names = ["us-east-2e"]
  provider = aws.us-east-2
  state    = "available"
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "public_us" {
  count             = length(data.aws_availability_zones.default_us.names)
  availability_zone = data.aws_availability_zones.default_us.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  provider          = aws.us-east-2
  vpc_id            = aws_vpc.default_us.id
  tags = {
    Name    = "replication-us-public"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "public_us" {
  count          = length(data.aws_availability_zones.default_us.names)
  provider       = aws.us-east-2
  route_table_id = aws_route_table.public_us.id
  subnet_id      = aws_subnet.public_us[count.index].id
}
