# Make a key for unsealing.
resource "aws_kms_key" "default" {
  description = var.name
  tags        = var.tags
}

# Make a policy to allow role assumption.
data "aws_iam_policy_document" "assumerole" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Make a policy to allow auto joining and auto unsealing.
data "aws_iam_policy_document" "join_unseal" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
    ]
    resources = [
      aws_kms_key.default.arn
    ]
  }
}

# Make a role to allow role assumption.
resource "aws_iam_role" "default" {
  assume_role_policy = data.aws_iam_policy_document.assumerole.json
  name               = var.name
  tags               = var.tags
}

# Link the default role to the join_unseal policy.
resource "aws_iam_role_policy" "default" {
  name   = "${var.name}-join_unseal"
  policy = data.aws_iam_policy_document.join_unseal.json
  role   = aws_iam_role.default.id
}

# Make an iam instance profile
resource "aws_iam_instance_profile" "default" {
  name = var.name
  role = aws_iam_role.default.name
  tags = var.tags
}

# Write user_data.sh for the Vault instances.
resource "local_file" "default" {
  directory_permission = "0755"
  file_permission      = "0640"
  filename             = "user_data.sh"
  content = templatefile("${path.module}/user_data.sh.tpl",
    {
      api_addr          = coalesce(var.api_addr, "https://${aws_lb.api.dns_name}:8200")
      cluster_addr      = try(var.cluster_addr, null)
      default_lease_ttl = var.default_lease_ttl
      kms_key_id        = aws_kms_key.default.id
      log_level         = var.log_level
      max_lease_ttl     = var.max_lease_ttl
      name              = var.name
      random_string     = random_string.default.result
      region            = var.region
      vault_ca_cert     = file("tls/vault_ca.crt")
      vault_ca_key      = file("tls/vault_ca.pem")
      vault_path        = var.vault_path
      vault_ui          = var.vault_ui
      vault_version     = var.vault_version
      vault_package     = local.vault_package
      vault_license     = try(var.vault_license, null)
    }
  )
}

# Create a VPC.
resource "aws_vpc" "default" {
  count      = var.vpc_id == "" ? 1 : 0
  cidr_block = local.cidr_block
  tags       = var.tags
}

# Create an internet gateway.
resource "aws_internet_gateway" "default" {
  count  = var.vpc_id == "" ? 1 : 0
  tags   = var.tags
  vpc_id = local.vpc_id
}

data "aws_internet_gateway" "default" {
  count = var.vpc_id == "" ? 0 : 1
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "default" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = local.vpc_id
}

data "aws_route_tables" "default" {
  count  = var.vpc_id == "" ? 0 : 1
  vpc_id = local.vpc_id
}

# Add an internet route to the internet gateway.
resource "aws_route" "default" {
  count                  = var.vpc_id == "" ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.internet_gateway_id
  route_table_id         = local.aws_route_table_id
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "default" {
  count             = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  availability_zone = data.aws_availability_zones.default.names[count.index]
  cidr_block        = "${var.aws_vpc_cidr_block_start}.${count.index}.0/24"
  tags              = var.tags
  vpc_id            = local.vpc_id
}

# Find subnets if the vpc was specified.
data "aws_subnets" "default" {
  count = var.vpc_id == "" ? 0 : 1
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "default" {
  count          = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  route_table_id = local.aws_route_table_id
  subnet_id      = local.aws_subnet_ids[count.index]
}

# Find availability_zones in this region.
data "aws_availability_zones" "default" {
  state = "available"
}

# Place an SSH key.
resource "aws_key_pair" "default" {
  count      = var.key_filename == "" ? 0 : 1
  key_name   = var.name
  public_key = file(var.key_filename)
  tags       = var.tags
}

# Find amis for the Vault instances.
data "aws_ami" "default" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [local.ami_pattern]
  }
}

# Create a security group for the loadbalancer.
resource "aws_security_group" "public" {
  name   = "${var.name}-public"
  tags   = var.tags
  vpc_id = local.vpc_id
}

# Allow the vault API to be accessed from the internet.
resource "aws_security_group_rule" "api_public" {
  cidr_blocks       = var.allowed_cidr_blocks
  description       = "Vault API"
  from_port         = 8200
  protocol          = "TCP"
  security_group_id = aws_security_group.public.id
  to_port           = 8200
  type              = "ingress"
}

# Create a security group for the instances.
resource "aws_security_group" "private" {
  name   = "${var.name}-private"
  tags   = var.tags
  vpc_id = local.vpc_id
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

# Allow other clusters to use Raft. (Required for "DR" and "PR", both enterprise features.)
resource "aws_security_group_rule" "clustertocluster" {
  count             = var.vault_type == "enterprise" ? 1 : 0
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

# Create a launch configuration.
resource "aws_launch_configuration" "default" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.default.name
  image_id                    = data.aws_ami.default.id
  instance_type               = local.instance_type
  key_name                    = local.key_name
  name_prefix                 = "${var.name}-"
  security_groups             = [aws_security_group.private.id, aws_security_group.public.id]
  spot_price                  = var.size == "development" ? var.spot_price : null
  user_data                   = local_file.default.content
  root_block_device {
    encrypted   = false
    iops        = local.volume_iops
    volume_size = local.volume_size
    volume_type = local.volume_type
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create a placement group that spreads.
resource "aws_placement_group" "default" {
  name     = var.name
  strategy = "spread"
  tags     = var.tags
}

# Add a load balancer for the API/UI.
resource "aws_lb" "api" {
  load_balancer_type = "application"
  name               = "${var.name}-api"
  security_groups    = [aws_security_group.public.id, aws_security_group.private.id]
  subnets            = local.aws_subnet_ids
  tags               = var.tags
}

# Add a load balancer for replication.
resource "aws_lb" "replication" {
  count              = var.vault_type == "enterprise" ? 1 : 0
  load_balancer_type = "network"
  name               = "${var.name}-replication"
  subnets            = local.aws_subnet_ids
  tags               = var.tags
}


# Create a load balancer target group for the API/UI.
resource "aws_lb_target_group" "api" {
  name_prefix = "${var.name}-"
  port        = 8200
  protocol    = "HTTPS"
  tags        = var.tags
  vpc_id      = local.vpc_id
  health_check {
    interval = 5
    path     = "/v1/sys/health"
    protocol = "HTTPS"
    timeout  = 2
  }
}

# Create a load balancer target group.
resource "aws_lb_target_group" "replication" {
  count              = var.vault_type == "enterprise" ? 1 : 0
  name_prefix = "${var.name}-"
  port        = 8201
  protocol    = "TCP"
  tags        = var.tags
  vpc_id      = local.vpc_id
}

# Add a API listener to the loadbalancer.
resource "aws_lb_listener" "api" {
  certificate_arn   = var.certificate_arn
  load_balancer_arn = aws_lb.api.arn
  port              = 8200
  protocol          = "HTTPS"
  tags              = var.tags
  default_action {
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"
  }
}

# Add a replication listener to the loadbalancer.
resource "aws_lb_listener" "replication" {
  count              = var.vault_type == "enterprise" ? 1 : 0
  load_balancer_arn = aws_lb.replication[0].arn
  port              = 8201
  protocol          = "TCP"
  tags              = var.tags
  default_action {
    target_group_arn = aws_lb_target_group.replication[0].arn
    type             = "forward"
  }
}

# Create a random string to make tags more unique.
resource "random_string" "default" {
  length  = 6
  number  = false
  special = false
  upper   = false
}

# Create an auto scaling group.
resource "aws_autoscaling_group" "default" {
  default_cooldown      = var.cooldown
  desired_capacity      = var.amount
  enabled_metrics       = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupPendingCapacity", "GroupMinSize", "GroupMaxSize", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupStandbyCapacity", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances"]
  health_check_type     = "EC2"
  launch_configuration  = aws_launch_configuration.default.name
  max_instance_lifetime = var.max_instance_lifetime
  max_size              = var.amount + 1
  min_size              = var.amount - 1
  name                  = var.name
  placement_group       = aws_placement_group.default.id
  target_group_arns     = compact([aws_lb_target_group.api.arn, try(aws_lb_target_group.replication[0].arn, null)])
  vpc_zone_identifier   = tolist(local.aws_subnet_ids)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      instance_warmup        = 300
      min_healthy_percentage = 90
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "vault-${var.name}-${random_string.default.result}"
  }
  timeouts {
    delete = "15m"
  }
}

# Create one security group in the single VPC.
resource "aws_security_group" "bastion" {
  count  = var.bastion_host ? 1 : 0
  name   = "${var.name}-bastion"
  tags   = var.tags
  vpc_id = local.vpc_id
}

# Allow SSH to the security group.
resource "aws_security_group_rule" "bastion-ssh" {
  count             = var.bastion_host ? 1 : 0
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
  count             = var.bastion_host ? 1 : 0
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
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

# Write user_data.sh for the Bastion instance.
resource "local_file" "bastion" {
  directory_permission = "0755"
  file_permission      = "0640"
  filename             = "bastion_user_data.sh"
  content = templatefile("${path.module}/bastion_user_data.sh.tpl",
    {
      api_addr          = coalesce(var.api_addr, "https://${aws_lb.api.dns_name}:8200")
      vault_ca_cert     = file("tls/vault_ca.crt")
      vault_version     = var.vault_version
      vault_package     = local.vault_package
      vault_path        = var.vault_path
    }
  )
}

# Create the bastion host.
resource "aws_instance" "bastion" {
  count                       = var.bastion_host ? 1 : 0
  ami                         = data.aws_ami.bastion.id
  associate_public_ip_address = true
  instance_type               = "t4g.nano"
  key_name                    = local.key_name
  monitoring                  = true
  subnet_id                   = tolist(local.aws_subnet_ids)[0]
  tags                        = local.bastion_tags
  user_data                   = local_file.bastion.content
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
}

# Collect the created vault instances.
data "aws_instances" "default" {
  instance_state_names = ["running"]
  instance_tags = {
    name = "${var.name}-${random_string.default.result}"
  }
  depends_on = [aws_autoscaling_group.default]
}
