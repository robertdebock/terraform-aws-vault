# Some resources are created in other `*.tf` files. Terraform calculates the
# order in which the resources must be created.

# Make a key for unsealing.
resource "aws_kms_key" "default" {
  count       = var.aws_kms_key_id == "" ? 1 : 0
  description = "Vault unseal key - ${var.name}"
  tags        = local.tags
}

# Find the key for unsealing.
data "aws_kms_key" "default" {
  count  = var.aws_kms_key_id == "" ? 0 : 1
  key_id = var.aws_kms_key_id
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
  user_data       = templatefile("${path.module}/user_data_vault.sh.tpl",
    {
      api_addr                       = local.api_addr
      default_lease_ttl              = var.default_lease_ttl
      instance_name                  = local.instance_name
      kms_key_id                     = local.aws_kms_key_id
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
      warmup                         = var.warmup
    }
  )
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
  health_check_type     = var.telemetry && !var.telemetry_unauthenticated_metrics_access ? "EC2" : "ELB"
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
      instance_warmup        = var.warmup
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

# Collect the created vault instances.
data "aws_instances" "default" {
  instance_state_names = ["running"]
  instance_tags = {
    Name = local.instance_name
  }
  depends_on = [aws_autoscaling_group.default]
}
