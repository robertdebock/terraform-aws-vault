# Create a security group for the loadbalancer.
resource "aws_security_group" "public" {
  description = "Public"
  name_prefix = "${var.name}-public-"
  tags        = local.public_tags
  vpc_id      = local.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

# Allow the vault API to be accessed from the internet.
resource "aws_security_group_rule" "api_public" {
  # TODO: Is this static or variable?
  # cidr_blocks       = var.allowed_cidr_blocks
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Vault API"
  from_port         = 8200
  protocol          = "TCP"
  security_group_id = aws_security_group.public.id
  to_port           = 8200
  type              = "ingress"
}

# Create a security group for the instances.
resource "aws_security_group" "private" {
  description = "Private"
  name_prefix = "${var.name}-private-"
  tags        = local.private_tags
  vpc_id      = local.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

# Allow the Vault API to be accessed from clients.
resource "aws_security_group_rule" "api_private" {
  description              = "vault api"
  from_port                = 8200
  protocol                 = "TCP"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.private.id
  to_port                  = 8200
  type                     = "ingress"
}

# Allow instances to use Raft.
resource "aws_security_group_rule" "raft" {
  description              = "server to server"
  from_port                = 8201
  protocol                 = "TCP"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.private.id
  to_port                  = 8201
  type                     = "ingress"
}

# Allow other clusters to use Raft. (This is an enterprise feature.)
resource "aws_security_group_rule" "clustertocluster" {
  count             = var.vault_replication ? 1 : 0
  cidr_blocks       = var.allowed_cidr_blocks_replication
  description       = "Vault Raft"
  from_port         = 8201
  protocol          = "TCP"
  security_group_id = aws_security_group.public.id
  to_port           = 8201
  type              = "ingress"
}

# Allow access from the bastion host.
resource "aws_security_group_rule" "ssh" {
  cidr_blocks       = [local.cidr_block]
  description       = "ssh"
  from_port         = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.private.id
  to_port           = 22
  type              = "ingress"
}

# Allow internet from the instances. Required for package installations.
resource "aws_security_group_rule" "internet" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.private.id
  to_port           = 0
  type              = "egress"
}
