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

# Create one VPC.
resource "aws_vpc" "default" {
  cidr_block = local.cidr_block
  tags       = var.tags
}

# Create an internet gateway.
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags   = var.tags
}

# Create a routing table for the internet gateway.
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id
}

# Add an internet route to the internet gateway.
resource "aws_route" "default" {
  route_table_id         = aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create the same amount of subnets as the amount of instances.
resource "aws_subnet" "default" {
  count             = min(length(data.aws_availability_zones.default.names), var.amount)
  vpc_id            = aws_vpc.default.id
  cidr_block        = "${var.aws_vpc_cidr_block_start}.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.default.names[count.index]
  tags              = var.tags
}

# Associate the subnet to the routing table.
resource "aws_route_table_association" "default" {
  count = min(length(data.aws_availability_zones.default.names), var.amount)
  subnet_id      = aws_subnet.default[count.index].id
  route_table_id = aws_route_table.default.id
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
  vpc_id = aws_vpc.default.id
  tags   = var.tags
}

# Allow the vault API to be accessed.
resource "aws_security_group_rule" "vaultapi" {
  description       = "vault api"
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}
resource "aws_security_group_rule" "vaultreplication" {
  description       = "vault replication"
  type              = "ingress"
  from_port         = 8201
  to_port           = 8201
  protocol          = "TCP"
  cidr_blocks       = [aws_vpc.default.cidr_block]
  security_group_id = aws_security_group.default.id
}

# Allow access from the bastion host.
resource "aws_security_group_rule" "ssh" {
  description       = "ssh"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = [aws_vpc.default.cidr_block]
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
  name                        = "${var.name}-${var.launch_configuration_version}"
  image_id                    = data.aws_ami.default.id
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.default.id
  security_groups             = [aws_security_group.default.id]
  iam_instance_profile        = aws_iam_instance_profile.default.name
  user_data                   = local_file.default.content
  associate_public_ip_address = true
  spot_price                  = var.size == "development" ? "0.012" : null
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
  subnets            = aws_subnet.default.*.id
  tags               = var.tags
}

# Create a load balancer target group.
resource "aws_lb_target_group" "default" {
  name     = var.name
  port     = 8200
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
  tags     = var.tags
  health_check {
    protocol = "HTTP"
    # port     = "traffic-port"
    path     = "/v1/sys/health"
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
  name                      = var.name
  desired_capacity          = var.amount
  min_size                  = var.amount
  max_size                  = var.amount
  health_check_type         = "EC2"
  default_cooldown          = 180
  placement_group           = aws_placement_group.default.id
  max_instance_lifetime     = var.max_instance_lifetime
  vpc_zone_identifier       = tolist(aws_subnet.default[*].id)
  target_group_arns         = tolist(aws_lb_target_group.default[*].arn)
  launch_configuration      = aws_launch_configuration.default.name
  enabled_metrics           = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupPendingCapacity", "GroupMinSize", "GroupMaxSize", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupStandbyCapacity", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances"]
  tag {
    key                 = "name"
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
  name   = "${var.name}-bastion"
  vpc_id = aws_vpc.default.id
  tags   = var.tags
}

# Allow SSH to the security group.
resource "aws_security_group_rule" "bastion-ssh" {
  description       = "ssh"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

# Allow internet access.
resource "aws_security_group_rule" "bastion-internet" {
  description       = "internet"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

# Create the bastion host.
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.default.id
  subnet_id                   = aws_subnet.default[0].id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.bastion.id]
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
