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
  cidr_blocks       = var.vault_bastion_allowed_cidr_blocks
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
  cidr_block        = cidrsubnet(var.vault_cidr_block, 8, count.index + 127)
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
  gateway_id             = var.vault_bastion_public_ip ? local.gateway_id : try(data.aws_nat_gateway.default[0].id, aws_nat_gateway.default[0].id)
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
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = var.vault_bastion_public_ip
  instance_type               = "t4g.nano"
  key_name                    = local.vault_aws_key_name
  subnet_id                   = aws_subnet.bastion[0].id
  tags                        = local.bastion_tags
  user_data = templatefile("${path.module}/templates/user_data_bastion.sh.tpl",
    {
      api_addr                           = local.api_addr
      vault_ca_cert_path                 = file("tls/vault_ca.crt")
      vault_bastion_custom_script_s3_url = var.vault_bastion_custom_script_s3_url
      vault_version                      = var.vault_version
      vault_package                      = local.vault_package
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

# Make an S3 bucket to store backups.
resource "aws_s3_bucket" "bastion" {
  bucket = "vault-backups-${random_string.default.result}"
  tags   = local.scripts_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bastion" {
  bucket = aws_s3_bucket.bastion.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.aws_kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Make a role to allow role assumption.
resource "aws_iam_role" "bastion" {
  assume_role_policy = data.aws_iam_policy_document.assumerole.json
  description        = "Vault bastion role - ${var.vault_name}"
  name               = "${var.vault_name}-bastion"
  tags               = local.tags
}

# Make a policy to allow downloading custom scripts from S3.
data "aws_iam_policy_document" "custom_scripts_bastion" {
  count = var.vault_custom_script_s3_url == "" ? 0 : 1
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${var.vault_bastion_custom_script_s3_bucket_arn}/*.sh"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${var.vault_bastion_custom_script_s3_bucket_arn}"
    ]
  }
}

# Make a policy to allow storing backups to S3.
data "aws_iam_policy_document" "backup" {
  count = var.vault_bastion_create_s3_bucket ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}/*.snap",
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}/*/*.snap"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucketVersions",
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}",
      "arn:aws:s3:::${var.vault_aws_s3_snapshots_bucket_name}/*"
    ]
  }
}

# Link the backup policy to the bastion role.
resource "aws_iam_role_policy" "backup" {
  count  = var.vault_bastion_create_s3_bucket ? 1 : 0
  name   = "${var.vault_name}-vault-bastion-backup"
  policy = data.aws_iam_policy_document.backup[0].json
  role   = aws_iam_role.bastion.id
}

# Link the custom script policy to the bastion role.
resource "aws_iam_role_policy" "custom_script" {
  count  = var.vault_custom_script_s3_url == "" ? 0 : 1
  name   = "${var.vault_name}-vault-bastion-custom_script"
  policy = data.aws_iam_policy_document.custom_scripts_bastion[0].json
  role   = aws_iam_role.bastion.id
}


# Make an iam instance profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.vault_name}-bastion"
  role = aws_iam_role.bastion.name
  tags = local.tags
}
