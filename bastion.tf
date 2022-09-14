# Create one security group in the single VPC.
resource "aws_security_group" "bastion" {
  count       = var.vault_create_bastionhost ? 1 : 0
  description = "Bastion - Traffic to bastion host"
  name_prefix = "${var.vault_name}-bastion-"
  tags        = local.bastion_tags
  vpc_id      = local.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

# Allow SSH to the security group.
resource "aws_security_group_rule" "bastion-ssh" {
  count             = var.vault_create_bastionhost ? 1 : 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "ssh"
  from_port         = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.bastion[0].id
  to_port           = 22
  type              = "ingress"
}

# Allow internet access.
resource "aws_security_group_rule" "bastion-internet" {
  count             = var.vault_create_bastionhost ? 1 : 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.bastion[0].id
  to_port           = 0
  type              = "egress"
}

# Find amis for the Bastion instance.
data "aws_ami" "bastion" {
  count       = var.vault_create_bastionhost ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

# Place the bastion host and the nat_gateway in it's own subnet.
resource "aws_subnet" "bastion" {
  count             = var.vault_create_bastionhost ? 1 : 0
  availability_zone = data.aws_availability_zones.default.names[0]
  cidr_block        = "${var.vault_vpc_cidr_block_start}.127.0/24"
  tags              = local.bastion_tags
  vpc_id            = local.vpc_id
}

# Create a routing table for the bastion instance.
resource "aws_route_table" "bastion" {
  count  = var.vault_create_bastionhost ? 1 : 0
  tags   = local.bastion_tags
  vpc_id = local.vpc_id
}

# Add an internet route to the internet gateway.
resource "aws_route" "bastion" {
  count                  = var.vault_create_bastionhost ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.gateway_id
  route_table_id         = aws_route_table.bastion[0].id
}

# Associate a route to the bastion subnet.
resource "aws_route_table_association" "bastion" {
  count          = var.vault_create_bastionhost ? 1 : 0
  route_table_id = aws_route_table.bastion[0].id
  subnet_id      = aws_subnet.bastion[0].id
}

# Create the bastion host.
resource "aws_instance" "bastion" {
  count                       = var.vault_create_bastionhost ? 1 : 0
  ami                         = data.aws_ami.bastion[0].id
  associate_public_ip_address = true
  instance_type               = "t4g.nano"
  key_name                    = local.vault_aws_key_name
  subnet_id                   = aws_subnet.bastion[0].id
  tags                        = local.bastion_tags
  user_data = templatefile("${path.module}/user_data_bastion.sh.tpl",
    {
      api_addr           = local.api_addr
      vault_ca_cert_path = file("tls/vault_ca.crt")
      vault_version      = var.vault_version
      vault_package      = local.vault_package
    }
  )
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  root_block_device {
    volume_size           = "32"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }
  depends_on = [local.gateway_id]
}
