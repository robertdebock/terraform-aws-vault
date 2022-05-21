# Make a key for unsealing.
resource "aws_kms_key" "default" {
  description = "Vault unseal key - ${var.name}"
  tags        = local.tags
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
  description        = "Vault role - ${var.name}"
  name               = var.name
  tags               = local.tags
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
  tags = local.tags
}

# Write user_data.sh for the Vault instances.
resource "local_file" "vault" {
  directory_permission = "0755"
  file_permission      = "0640"
  filename             = "user_data_vault.sh"
  content = templatefile("${path.module}/user_data_vault.sh.tpl",
    {
      api_addr                       = local.api_addr
      default_lease_ttl              = var.default_lease_ttl
      instance_name                  = local.instance_name
      kms_key_id                     = aws_kms_key.default.id
      log_level                      = var.log_level
      max_lease_ttl                  = var.max_lease_ttl
      name                           = var.name
      prometheus_disable_hostname    = var.prometheus_disable_hostname
      prometheus_retention_time      = var.prometheus_retention_time
      random_string                  = random_string.default.result
      region                         = var.region
      telemetry                      = var.telemetry
      unauthenticated_metrics_access = var.telemetry_unauthenticated_metrics_access
      vault_ca_cert                  = file(var.vault_ca_cert)
      vault_ca_key                   = file(var.vault_ca_key)
      vault_path                     = var.vault_path
      vault_ui                       = var.vault_ui
      vault_version                  = var.vault_version
      vault_package                  = local.vault_package
      vault_license                  = try(var.vault_license, null)
    }
  )
}

# Create a VPC.
resource "aws_vpc" "default" {
  count      = var.vpc_id == "" ? 1 : 0
  cidr_block = local.cidr_block
  tags       = local.tags
}

# Create an internet gateway if the VPC is not provided.
resource "aws_internet_gateway" "default" {
  count  = var.vpc_id == "" ? 1 : 0
  tags   = local.tags
  vpc_id = local.vpc_id
}

# Reserve external IP addresses. (It's for the NAT gateways.)
resource "aws_eip" "default" {
  count = var.vpc_id == "" ? 1 : 0
  tags  = local.tags
  vpc   = true
}

# Make NAT gateways, for the Vault instances to reach the internet.
resource "aws_nat_gateway" "default" {
  count         = var.vpc_id == "" ? 1 : 0
  allocation_id = aws_eip.default[0].id
  subnet_id     = aws_subnet.public[0].id
  tags          = local.tags
  depends_on    = [aws_internet_gateway.default]
}

# Create a routing table for the Vault instances.
resource "aws_route_table" "private" {
  count  = var.vpc_id == "" ? 1 : 0
  tags   = local.private_tags
  vpc_id = local.vpc_id
}

# Add a route to the routing table for the Vault instances.
resource "aws_route" "private" {
  count                  = var.vpc_id == "" ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default[0].id
  route_table_id         = aws_route_table.private[0].id
}

# Add a route table to pass traffic from "public" subnets to the internet gateway.
resource "aws_route_table" "public" {
  count  = var.vpc_id == "" ? 1 : 0
  tags   = local.public_tags
  vpc_id = local.vpc_id
}

# Add a route to the internet gateway for the public subnets.
resource "aws_route" "public" {
  count                  = var.vpc_id == "" ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default[0].id
}

# Create the same amount of (private) subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "private" {
  count             = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  availability_zone = data.aws_availability_zones.default.names[count.index]
  cidr_block        = "${var.vpc_cidr_block_start}.${count.index}.0/24"
  tags              = local.private_tags
  vpc_id            = local.vpc_id
}

# # Create (public) subnets to allow the loadbalancer to route traffic to intances.
resource "aws_subnet" "public" {
  count             = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  availability_zone = data.aws_availability_zones.default.names[count.index]
  cidr_block        = "${var.vpc_cidr_block_start}.${count.index + 64}.0/24"
  tags              = local.public_tags
  vpc_id            = local.vpc_id
}

# Associate the private subnet to the routing table.
resource "aws_route_table_association" "private" {
  count          = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  route_table_id = aws_route_table.private[0].id
  subnet_id      = local.private_subnet_ids[count.index]
}

# Associate the public subnet to the public routing table.
resource "aws_route_table_association" "public" {
  count          = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  route_table_id = aws_route_table.public[0].id
  subnet_id      = aws_subnet.public[count.index].id
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
  tags       = local.tags
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

# Create a launch configuration.
resource "aws_launch_configuration" "default" {
  iam_instance_profile = aws_iam_instance_profile.default.name
  image_id             = data.aws_ami.default.id
  instance_type        = local.instance_type
  key_name             = local.key_name
  name_prefix          = "${var.name}-"
  # TODO: Are both security groups required?
  security_groups = [aws_security_group.private.id, aws_security_group.public.id]
  spot_price      = var.size == "development" ? var.spot_price : null
  user_data       = local_file.vault.content
  root_block_device {
    encrypted   = true
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
  tags     = local.tags
}

# Add a load balancer for the API/UI.
resource "aws_lb" "api" {
  name            = "${var.name}-api"
  security_groups = [aws_security_group.public.id, aws_security_group.private.id]
  subnets         = local.public_subnet_ids
  tags            = local.api_tags
}

# Add a load balancer for replication.
resource "aws_lb" "replication" {
  count              = var.vault_replication ? 1 : 0
  load_balancer_type = "network"
  name               = "${var.name}-replication"
  # TODO: No security groups?
  subnets = local.public_subnet_ids
  tags    = local.replication_tags
}

# Create a load balancer target group for the API/UI.
resource "aws_lb_target_group" "api" {
  name_prefix = "${var.name}-"
  port        = 8200
  protocol    = "HTTPS"
  tags        = local.api_tags
  vpc_id      = local.vpc_id
  health_check {
    interval = 5
    # "200": Raft leaders should not be replaced.
    # "429": Raft standby nodes should not be replaced.
    # "472": Nodes of Disaster recovery cluster should not be replaced.
    # "473": Nodes of Performance replication cluster should not be replaced.
    # See https://www.vaultproject.io/api-docs/system/health
    # if telemetry is enabled, AND unauthenticated_metrics_access is disabled,
    # don't consider raft followers healthy, only send traffic to the leader.
    #
    # | telemetry | unauthenticated_metrics_access | vault nodes to use   |
    # |-----------|--------------------------------|----------------------|
    # | true      | true                           | leader and followers |
    # | true      | false                          | leader only          |
    # | false     | false                          | leader and followers |
    # | false     | true                           | leader and followers |
    matcher  = var.telemetry && !var.unauthenticated_metrics_access ? "200,472,473" : "200,429,472,473"
    path     = "/v1/sys/health"
    protocol = "HTTPS"
    timeout  = 2
  }
}

# Create a load balancer target group.
resource "aws_lb_target_group" "replication" {
  count       = var.vault_replication ? 1 : 0
  name_prefix = "${var.name}-"
  port        = 8201
  protocol    = "TCP"
  tags        = local.replication_tags
  vpc_id      = local.vpc_id
}

# Add a API listener to the loadbalancer.
resource "aws_lb_listener" "api" {
  certificate_arn   = var.certificate_arn
  load_balancer_arn = aws_lb.api.arn
  # TODO: make this port variable.
  port              = 8200
  protocol          = "HTTPS"
  tags              = local.api_tags
  default_action {
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"
  }
}

# Add a replication listener to the loadbalancer.
resource "aws_lb_listener" "replication" {
  count             = var.vault_replication ? 1 : 0
  load_balancer_arn = aws_lb.replication[0].arn
  port              = 8201
  protocol          = "TCP"
  tags              = local.replication_tags
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
  health_check_type     = var.telemetry && !var.unauthenticated_metrics_access ? "EC2" : "ELB"
  launch_configuration  = aws_launch_configuration.default.name
  max_instance_lifetime = var.max_instance_lifetime
  max_size              = var.amount + 1
  min_size              = var.amount - 1
  name                  = var.name
  placement_group       = aws_placement_group.default.id
  target_group_arns     = local.target_group_arns
  vpc_zone_identifier   = local.private_subnet_ids
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
    value               = local.instance_name
  }
  timeouts {
    delete = "15m"
  }
}

# Create one security group in the single VPC.
resource "aws_security_group" "bastion" {
  count       = var.bastion_host ? 1 : 0
  description = "Bastion"
  name_prefix = "${var.name}-bastion-"
  tags        = local.bastion_tags
  vpc_id      = local.vpc_id
  lifecycle {
    create_before_destroy = true
  }
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
  count       = var.bastion_host ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

# Write user_data.sh for the Bastion instance.
resource "local_file" "bastion" {
  count                = var.bastion_host ? 1 : 0
  directory_permission = "0755"
  file_permission      = "0640"
  filename             = "user_data_bastion.sh"
  content = templatefile("${path.module}/user_data_bastion.sh.tpl",
    {
      api_addr      = local.api_addr
      vault_ca_cert = file("tls/vault_ca.crt")
      vault_version = var.vault_version
      vault_package = local.vault_package
      vault_path    = var.vault_path
    }
  )
}

# Place the bastion host and the nat_gateway in it's own subnet.
resource "aws_subnet" "bastion" {
  count             = var.bastion_host ? 1 : 0
  availability_zone = data.aws_availability_zones.default.names[0]
  cidr_block        = "${var.vpc_cidr_block_start}.127.0/24"
  tags              = local.bastion_tags
  vpc_id            = local.vpc_id
}

# Create a routing table for the bastion instance.
resource "aws_route_table" "bastion" {
  count  = var.bastion_host ? 1 : 0
  tags   = local.bastion_tags
  vpc_id = local.vpc_id
}

# Find internet gateways if no vpc_id was specified.
data "aws_internet_gateway" "default" {
  count = var.vpc_id != "" && var.bastion_host ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

# Add an internet route to the internet gateway.
resource "aws_route" "bastion" {
  count                  = var.bastion_host ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.gateway_id
  route_table_id         = aws_route_table.bastion[0].id
}

# Associate a route to the bastion subnet.
resource "aws_route_table_association" "bastion" {
  count          = var.bastion_host ? 1 : 0
  route_table_id = aws_route_table.bastion[0].id
  subnet_id      = aws_subnet.bastion[0].id
}

# Create the bastion host.
resource "aws_instance" "bastion" {
  count                       = var.bastion_host ? 1 : 0
  ami                         = data.aws_ami.bastion[0].id
  associate_public_ip_address = true
  instance_type               = "t4g.nano"
  key_name                    = local.key_name
  monitoring                  = true
  subnet_id                   = aws_subnet.bastion[0].id
  tags                        = local.bastion_tags
  user_data                   = local_file.bastion[0].content
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  root_block_device {
    volume_size           = "32"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }
  depends_on                  = [local.gateway_id]
}

# Collect the created vault instances.
data "aws_instances" "default" {
  instance_state_names = ["running"]
  instance_tags = {
    Name = local.instance_name
  }
  depends_on = [aws_autoscaling_group.default]
}
