# Create a security group for the loadbalancer.
resource "aws_security_group" "public" {
  count       = var.vault_aws_lb_availability == "external" ? 1 : 0
  description = "Public - Traffic to Vault nodes"
  name_prefix = "${var.vault_name}-public-"
  tags        = local.public_tags
  vpc_id      = local.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

# Allow the vault API to be accessed from the internet.
resource "aws_security_group_rule" "api_public" {
  count             = length(aws_security_group.public)
  cidr_blocks       = var.vault_allowed_cidr_blocks
  description       = "Vault API/UI"
  from_port         = var.vault_api_port
  protocol          = "TCP"
  security_group_id = aws_security_group.public[0].id
  to_port           = var.vault_api_port
  type              = "ingress"
}

# Allow the redirection from port 80 to `var.vault_api_port` from the internet.
resource "aws_security_group_rule" "api_public_redirect" {
  count             = length(aws_security_group.public)
  cidr_blocks       = var.vault_allowed_cidr_blocks
  description       = "Vault API/UI redirection"
  from_port         = 80
  protocol          = "TCP"
  security_group_id = aws_security_group.public[0].id
  to_port           = 80
  type              = "ingress"
}

# Allow specified security groups to have access as well.
resource "aws_security_group_rule" "extra" {
  count                    = length(aws_security_group.public) == 1 ? length(var.vault_extra_security_group_ids) : 0
  description              = "User specified security_group"
  from_port                = var.vault_api_port
  protocol                 = "TCP"
  security_group_id        = aws_security_group.public[0].id
  source_security_group_id = var.vault_extra_security_group_ids[count.index]
  to_port                  = var.vault_api_port
  type                     = "ingress"
}

# Create a security group for the instances.
resource "aws_security_group" "private" {
  description = "Private - Traffic to Vault nodes"
  name_prefix = "${var.vault_name}-private-"
  tags        = local.private_tags
  vpc_id      = local.vpc_id
  lifecycle {
    create_before_destroy = true
  }
}

# Allow the Vault API to be accessed from vault node to vault node.
resource "aws_security_group_rule" "api_private" {
  description              = "Vault API/UI"
  from_port                = 8200
  protocol                 = "TCP"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.private.id
  to_port                  = 8200
  type                     = "ingress"
}

# Allow the Vault API to be accessed from the bastion node on port 443.
resource "aws_security_group_rule" "api_bastion" {
  count                    = length(aws_security_group.bastion)
  description              = "Vault API/UI"
  from_port                = var.vault_api_port
  protocol                 = "TCP"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.bastion[count.index].id
  to_port                  = var.vault_api_port
  type                     = "ingress"
}

# Allow the Vault API to be accessed from the bastion node on port 80. (Redirecting)
resource "aws_security_group_rule" "api_bastion_http" {
  count                    = length(aws_security_group.bastion)
  description              = "Vault API/UI"
  from_port                = 80
  protocol                 = "TCP"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.bastion[count.index].id
  to_port                  = 80
  type                     = "ingress"
}


# Allow instances to use Raft.
resource "aws_security_group_rule" "raft" {
  description              = "Vault Raft"
  from_port                = 8201
  protocol                 = "TCP"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.private.id
  to_port                  = 8201
  type                     = "ingress"
}

# Allow other clusters to use Raft. (This is an enterprise feature.)
resource "aws_security_group_rule" "clustertocluster" {
  count             = var.vault_allow_replication && length(aws_security_group.public) == 1 ? 1 : 0
  cidr_blocks       = var.vault_allowed_cidr_blocks_replication
  description       = "Vault Raft Replication"
  from_port         = var.vault_replication_port
  protocol          = "TCP"
  security_group_id = aws_security_group.public[0].id
  to_port           = var.vault_replication_port
  type              = "ingress"
}

# Allow access from the bastion host.
resource "aws_security_group_rule" "ssh" {
  count             = var.vault_allow_ssh ? 1 : 0
  cidr_blocks       = [var.vault_cidr_block]
  description       = "SSH from bastion"
  from_port         = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.private.id
  to_port           = 22
  type              = "ingress"
}

# Allow internet from the instances. Required for package installations.
resource "aws_security_group_rule" "internet" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.private.id
  to_port           = 0
  type              = "egress"
}
