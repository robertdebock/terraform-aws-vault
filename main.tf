# Some resources are created in other `*.tf` files. Terraform calculates the
# order in which the resources must be created.

# Make a key for unsealing.
resource "aws_kms_key" "default" {
  count       = var.aws_kms_key_id == "" ? 1 : 0
  description = "Vault unseal key - ${var.vault_name}"
  tags        = local.tags
}

# Find the key for unsealing.
data "aws_kms_key" "default" {
  count  = var.aws_kms_key_id == "" ? 0 : 1
  key_id = var.aws_kms_key_id
}

# Find the region.
data "aws_region" "default" {}

# Place an SSH key.
resource "aws_key_pair" "default" {
  count      = var.vault_keyfile_path == "" ? 0 : 1
  key_name   = var.vault_name
  public_key = file(var.vault_keyfile_path)
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

# Create a launch template.
resource "aws_launch_template" "default" {
  iam_instance_profile {
    name = aws_iam_instance_profile.default.name
  }
  image_id = data.aws_ami.default.id
  instance_requirements {
    memory_mib {
      min = local.minimum_memory
    }
    vcpu_count {
      min = local.minimum_vcpus
    }
    cpu_manufacturers    = [var.cpu_manufacturer]
    instance_generations = ["current"]
  }
  key_name               = local.vault_aws_key_name
  name_prefix            = "${var.vault_name}-"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.private.id, aws_security_group.public.id]
  user_data = base64encode(templatefile("${path.module}/user_data_vault.sh.tpl",
    {
      api_addr                       = local.api_addr
      audit_device                   = var.audit_device
      audit_device_path              = var.audit_device_path
      audit_device_size              = var.audit_device_size
      cloudwatch_monitoring          = var.cloudwatch_monitoring
      default_lease_ttl              = var.default_lease_ttl
      instance_name                  = local.instance_name
      kms_key_id                     = local.aws_kms_key_id
      log_level                      = var.log_level
      max_lease_ttl                  = var.max_lease_ttl
      vault_name                     = var.vault_name
      prometheus_disable_hostname    = var.prometheus_disable_hostname
      prometheus_retention_time      = var.prometheus_retention_time
      random_string                  = random_string.default.result
      region                         = data.aws_region.default.name
      target_group_arns              = local.target_group_arns
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
  ))
  dynamic "block_device_mappings" {
    for_each = var.audit_device ? local.disks_with_audit : local.disks_without_audit
    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = flatten([try(block_device_mappings.value.ebs, [])])

        content {
          delete_on_termination = try(ebs.value.delete_on_termination, null)
          encrypted             = try(ebs.value.encrypted, null)
          iops                  = try(ebs.value.iops, null)
          volume_size           = try(ebs.value.volume_size, null)
          volume_type           = try(ebs.value.volume_type, null)
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

}

# Create a random string to make tags more unique.
resource "random_string" "default" {
  length  = 6
  numeric = false
  special = false
  upper   = false
}

# Create an auto scaling group.
resource "aws_autoscaling_group" "default" {
  default_cooldown = var.cooldown
  desired_capacity = local.amount
  enabled_metrics  = ["GroupDesiredCapacity", "GroupInServiceCapacity", "GroupPendingCapacity", "GroupMinSize", "GroupMaxSize", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupStandbyCapacity", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances"]
  # Base the health check on weaker "EC2" if:
  # - var.telemetry is enabled AND var.telemetry_unauthenticated_metrics_access is disabled.
  # Or if:
  # - var.vault_replication is enabled.
  # Otherwise, use "ELB", which is stronger, but not always applicable..
  # health_check_type   = var.telemetry && !var.telemetry_unauthenticated_metrics_access ? "EC2" : "ELB"
  health_check_type     = var.vault_replication || (var.telemetry && !var.telemetry_unauthenticated_metrics_access) ? "EC2" : "ELB"
  max_instance_lifetime = var.max_instance_lifetime
  max_size              = local.amount + 1
  min_size              = local.amount - 1
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.default.id
      }
      override {
        instance_requirements {
          memory_mib {
            min = local.minimum_memory
          }
          vcpu_count {
            min = local.minimum_vcpus
          }
        }
      }
    }
  }
  name            = var.vault_name
  placement_group = aws_placement_group.default.id
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = local.instance_name
  }
  target_group_arns   = local.target_group_arns
  vpc_zone_identifier = local.private_subnet_ids
  instance_refresh {
    preferences {
      instance_warmup        = var.warmup
      min_healthy_percentage = 90
    }
    strategy = "Rolling"
  }
  lifecycle {
    create_before_destroy = true
  }
  timeouts {
    delete = "15m"
  }
}
