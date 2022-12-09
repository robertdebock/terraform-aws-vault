# Make a key for unsealing.
resource "aws_kms_key" "default_eu" {
  description = "Vault unseal key"
  tags = {
    Name  = "replication-eu"
    owner = "robertdebock"
  }
}

# Create a VCP.
resource "aws_vpc" "default_eu" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name    = "replication-eu"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Create an internet gateway.
resource "aws_internet_gateway" "default_eu" {
  vpc_id = aws_vpc.default_eu.id
  tags = {
    Name    = "replication-eu"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "public_eu" {
  vpc_id = aws_vpc.default_eu.id
  tags = {
    Name = "replicaiton-eu-public"
  }
}

# Add an internet route to the internet gateway.
resource "aws_route" "public_eu" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default_eu.id
  route_table_id         = aws_route_table.public_eu.id
}

# Create a routing table for the nat gateway.
resource "aws_route_table" "private_eu" {
  vpc_id = aws_vpc.default_eu.id
  tags = {
    Name = "replication-eu-private"
  }
}

# Reserve external IP addresses. (It's for the NAT gateways.)
resource "aws_eip" "default_eu" {
  vpc = true
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "private_eu" {
  count             = length(data.aws_availability_zones.default_eu.names)
  availability_zone = data.aws_availability_zones.default_eu.names[count.index]
  cidr_block        = "10.1.${count.index + 64}.0/24"
  vpc_id            = aws_vpc.default_eu.id
  tags = {
    Name    = "replication-eu-private"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Make NAT gateways, for the Vault instances to reach the internet.
resource "aws_nat_gateway" "default_eu" {
  allocation_id = aws_eip.default_eu.id
  subnet_id     = aws_subnet.public_eu[0].id
  tags = {
    Name    = "replication-eu"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
  depends_on = [aws_internet_gateway.default_eu]
}

# Add an internet route to the nat gateway.
resource "aws_route" "private_eu" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default_eu.id
  route_table_id         = aws_route_table.private_eu.id
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "private_eu" {
  count          = length(data.aws_availability_zones.default_eu.names)
  route_table_id = aws_route_table.private_eu.id
  subnet_id      = aws_subnet.private_eu[count.index].id
}

# Find availability_zones in this region.
data "aws_availability_zones" "default_eu" {
  # The availability zone "us-east-1e" does not have all instance_types available.
  exclude_names = ["us-east-1e"]
  state = "available"
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "public_eu" {
  count             = length(data.aws_availability_zones.default_eu.names)
  availability_zone = data.aws_availability_zones.default_eu.names[count.index]
  cidr_block        = "10.1.${count.index}.0/24"
  vpc_id            = aws_vpc.default_eu.id
  tags = {
    Name    = "replication-eu-public"
    owner   = "robertdebock"
    purpose = "ci-pr-dr"
  }
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "public_eu" {
  count          = length(data.aws_availability_zones.default_eu.names)
  route_table_id = aws_route_table.public_eu.id
  subnet_id      = aws_subnet.public_eu[count.index].id
}
