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
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
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
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]
    resources = [
      aws_kms_key.default.arn
    ]
  }
}

# Make a role to allow role assumption.
resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assumerole.json
  tags               = var.tags
}

# Link the default role to the join_unseal policy.
resource "aws_iam_role_policy" "default" {
  name   = "${var.name}-join_unseal"
  role   = aws_iam_role.default.id
  policy = data.aws_iam_policy_document.join_unseal.json
}

# Make an iam instance profile
resource "aws_iam_instance_profile" "default" {
  name = var.name
  role = aws_iam_role.default.name
  tags = var.tags
}

# Write user_data.sh.
resource "local_file" "default" {
  content = templatefile("${path.module}/user_data.sh.tpl",
    {
      kms_key_id    = aws_kms_key.default.id
      region        = var.region
      name          = var.name
      vault_version = var.vault_version
    }
  )
  filename             = "${path.module}/user_data.sh"
  file_permission      = "0640"
  directory_permission = "0755"
}

# Create a VPC.
resource "aws_vpc" "default" {
  # Make a VPC when var.vpc_id is not set.
  count      = var.vpc_id == "" ? 1 : 0
  cidr_block = local.cidr_block
  tags       = var.tags
}

# Lookup a VPC.
data "aws_vpc" "default" {
  # Lookup a VPC when var.vpc_id is set.
  count = var.vpc_id == "" ? 0 : 1
  id    = var.vpc_id
}

# Create an internet gateway.
resource "aws_internet_gateway" "default" {
  # Create an internet gateway when a VPC has been created.
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = local.vpc_id
  tags   = var.tags
}

data "aws_internet_gateway" "default" {
  # Lookup an internet gateway when a VPC has been provided.
  count = var.vpc_id == "" ? 0 : 1
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "default" {
  # Make the routing table when a VPC has been created.
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = local.vpc_id
}

data "aws_route_tables" "default" {
  # Lookup the routing table when a VPC has been provided.
  count  = var.vpc_id == "" ? 0 : 1
  vpc_id = local.vpc_id
}

# Add an internet route to the internet gateway.
resource "aws_route" "default" {
  # Only add a route when a VPC has been created.
  count                  = var.vpc_id == "" ? 1 : 0
  route_table_id         = local.aws_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.internet_gateway_id
}

# Create the same amount of subnets as the amount of instances when we create the vpc.
resource "aws_subnet" "default" {
  # Only make an aws_subnet when the vpc has been generated.
  count             = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  vpc_id            = local.vpc_id
  cidr_block        = "${var.aws_vpc_cidr_block_start}.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags              = var.tags
}

data "aws_subnet_ids" "default" {
  count  = var.vpc_id == "" ? 0 : 1
  vpc_id = local.vpc_id
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "default" {
  count          = var.vpc_id == "" ? min(length(data.aws_availability_zones.default.names), var.amount) : 0
  subnet_id      = local.aws_subnet_ids[count.index]
  route_table_id = local.aws_route_table_id
}

# Find availability_zones in this region.
data "aws_availability_zones" "default" {
  state = "available"
}

# Place an SSH key.
resource "aws_key_pair" "default" {
  key_name   = var.name
  public_key = file(var.key_filename)
  tags       = var.tags
}

# Find amis.
data "aws_ami" "default" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

# Create a security group.
resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = local.vpc_id
  tags   = var.tags
}

# Allow the vault API to be accessed.
resource "aws_security_group_rule" "vaultapi" {
  description       = "vault api"
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "TCP"
  # TODO: Check if `[local.cidr_block]` breaks stuff.
  # TODO: With tcpdump, check the source of the LB health check. -> 172.16.0.168
  cidr_blocks       = ["0.0.0.0/0"]
  # TODO: Allow a user of this module to pick the cidr_blocks. (maybe 0/0, or something else.)
  security_group_id = aws_security_group.default.id
}

# TODO: Compare to

# TODO: Maybe 8200 egress is required.

resource "aws_security_group_rule" "vaultreplication" {
  # TODO: Rename `replicate` to something like ha-traffic or so. (`raft`)
  description       = "vault replication"
  type              = "ingress"
  from_port         = 8201
  to_port           = 8201
  protocol          = "TCP"
  cidr_blocks       = [local.cidr_block]
  security_group_id = aws_security_group.default.id
}

# Allow access from the bastion host.
resource "aws_security_group_rule" "ssh" {
  count             = var.bastion_host ? 1 : 0
  description       = "ssh"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = [local.cidr_block]
  security_group_id = aws_security_group.default.id
}

# Allow internet from the instances. Required for package installations.
resource "aws_security_group_rule" "internet" {
  description       = "internet"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

# Create a launch template.
resource "aws_launch_configuration" "default" {
  name_prefix                 = "${var.name}-"
  image_id                    = data.aws_ami.default.id
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.default.id
  security_groups             = [aws_security_group.default.id]
  iam_instance_profile        = aws_iam_instance_profile.default.name
  user_data                   = local_file.default.content
  associate_public_ip_address = true
  # TODO: 0.012 could be configurable.
  spot_price                  = var.size == "development" ? "0.012" : null
  root_block_device {
    volume_type = local.volume_type
    volume_size = local.volume_size
    iops        = local.volume_iops
  }
  # TODO: Take out the depends_on; it's already mentioned in user_data.
  depends_on                  = [local_file.default]
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

# Add a load balancer.
resource "aws_lb" "default" {
  name               = var.name
  load_balancer_type = "network"
  subnets            = local.aws_subnet_ids
  tags               = var.tags
}

# Create a load balancer target group.
resource "aws_lb_target_group" "default" {
  name     = var.name
  port     = 8200
  protocol = "TCP"
  vpc_id   = local.vpc_id
  tags     = var.tags
  health_check {
    protocol = "HTTP"
    # TODO: If using TLS, use `protocol = "HTTPS"'
    path = "/v1/sys/health"
  }
}

# Add a listener to the loadbalancer.
resource "aws_lb_listener" "default" {
  load_balancer_arn = aws_lb.default.arn
  port              = 8200
  protocol          = "TCP"
  tags              = var.tags
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

# Create an auto scaling group.
resource "aws_autoscaling_group" "default" {
  name                  = var.name
  desired_capacity      = var.amount
  min_size              = var.amount - 1
  max_size              = var.amount + 1
  health_check_type     = "EC2"
  placement_group       = aws_placement_group.default.id
  max_instance_lifetime = var.max_instance_lifetime
  # TODO: Fill Vault with a lot of data, then try refreshing.
  vpc_zone_identifier   = tolist(local.aws_subnet_ids)
  target_group_arns     = [aws_lb_target_group.default.arn]
  launch_configuration  = aws_launch_configuration.default.name
  enabled_metrics       = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupPendingCapacity", "GroupMinSize", "GroupMaxSize", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupStandbyCapacity", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances"]
  tag {
    key                 = "name"
    # TODO: Add some random string to make the tag value more unique. (Remember `user_data.sh.tpl`.)
    value               = var.name
    propagate_at_launch = true
  }
  timeouts {
    delete = "15m"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create one security group in the single VPC.
resource "aws_security_group" "bastion" {
  count  = var.bastion_host ? 1 : 0
  name   = "${var.name}-bastion"
  vpc_id = local.vpc_id
  tags   = var.tags
}

# Allow SSH to the security group.
resource "aws_security_group_rule" "bastion-ssh" {
  count             = var.bastion_host ? 1 : 0
  description       = "ssh"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
}

# Allow internet access.
resource "aws_security_group_rule" "bastion-internet" {
  count             = var.bastion_host ? 1 : 0
  description       = "internet"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
}

# Create the bastion host.
resource "aws_instance" "bastion" {
  count                       = var.bastion_host ? 1 : 0
  ami                         = data.aws_ami.default.id
  subnet_id                   = tolist(local.aws_subnet_ids)[0]
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  key_name                    = aws_key_pair.default.id
  associate_public_ip_address = true
  monitoring                  = true
  tags                        = var.tags
}

# Collect the created vault instances.
data "aws_instances" "default" {
  instance_state_names = ["running"]
  instance_tags = {
    name = var.name
  }
  depends_on = [aws_autoscaling_group.default]
}
