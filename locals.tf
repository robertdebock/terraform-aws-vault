locals {

  # Resolve the ip_addr, either set using `api_addr` or the created resource.
  api_addr = coalesce(var.vault_api_addr, "https://${aws_lb.api.dns_name}:${var.vault_api_port}")

  # Combine the variable `tags` with specific prefixes.
  api_tags         = merge({ Name = "api-${var.vault_name}-${random_string.default.result}" }, var.vault_tags)
  bastion_tags     = merge({ Name = "bastion-${var.vault_name}-${random_string.default.result}" }, var.vault_tags)
  private_tags     = merge({ Name = "private-${var.vault_name}-${random_string.default.result}" }, var.vault_tags)
  public_tags      = merge({ Name = "public-${var.vault_name}-${random_string.default.result}" }, var.vault_tags)
  replication_tags = merge({ Name = "replication-${var.vault_name}-${random_string.default.result}" }, var.vault_tags)
  scripts_tags     = merge({ Name = "scripts-${var.vault_name}-${random_string.default.result}" },  var.vault_tags)
  vpc_tags         = merge({ Name = "vpc-${var.vault_name}-${random_string.default.result}" },  var.vault_tags)
  tags             = merge({ Name = "${var.vault_name}-${random_string.default.result}" }, var.vault_tags)
  
  # Compose the name of the instances.
  instance_name = "vault-${var.vault_name}-${random_string.default.result}"

  # Compose a name for other resources.
  name = "${var.vault_name}-${random_string.default.result}"

  # Combine api arn and (optionally) replication arn.
  target_group_arns = compact([aws_lb_target_group.api.arn, try(aws_lb_target_group.replication[0].arn, null)])

  # A map of memory requirements.
  _minimum_memory = {
    custom      = var.vault_asg_minimum_required_memory
    development = 512
    minimum     = 8 * 1024
    small       = 16 * 1024
    large       = 32 * 1024
    maximum     = 64 * 1024
  }
  minimum_memory = local._minimum_memory[var.vault_size]

  # A map of cpu requirements.
  _minimum_vcpus = {
    custom      = var.vault_asg_minimum_required_vcpus
    development = 1
    minimum     = 2
    small       = 4
    large       = 4
    maximum     = 8
  }
  minimum_vcpus = local._minimum_vcpus[var.vault_size]

  # A map from `vault_size` to `volume_type`.
  _volume_type = {
    custom      = var.vault_volume_type
    development = "gp2"
    minimum     = "gp3"
    small       = "gp3"
    large       = "gp3"
    maximum     = "gp3"
  }
  volume_type = local._volume_type[var.vault_size]

  # A map from `vault_size` to `volume_size`.
  _volume_size = {
    custom      = var.vault_volume_size
    development = 8
    minimum     = 100
    small       = 100
    large       = 200
    maximum     = 200
  }
  volume_size = local._volume_size[var.vault_size]

  # A map from `vault_size` to `volume_iops`.
  _volume_iops = {
    custom      = var.vault_volume_iops
    development = 0
    minimum     = 3000
    small       = 3000
    large       = 10000
    maximum     = 10000
  }
  volume_iops = local._volume_iops[var.vault_size]

  # Resolve the key, either set using `vault_aws_key_name` or placed using `vault_keyfile_path`.
  vault_aws_key_name = try(aws_key_pair.default[0].id, var.vault_aws_key_name)

  # Form the cidr_block based on a variable.
  cidr_block = "${var.vault_vpc_cidr_block_start}.0.0/16"

  # Select the vpc_id, either created or set as a variable.
  vpc_id = try(aws_vpc.default[0].id, var.vault_aws_vpc_id)

  # Select the private_subnet_ids, either set as a variable or created.
  private_subnet_ids = coalescelist(var.vault_private_subnet_ids, aws_subnet.private[*].id)

  # Select the public_subnet_ids, either created or set as a variable.
  public_subnet_ids = try(coalescelist(var.vault_public_subnet_ids, aws_subnet.public[*].id), [])

  # Select the gateway_id, either the created resource or the found resource.
  gateway_id = try(aws_internet_gateway.default[0].id, data.aws_internet_gateway.default[0].id)

  # Set the key id, based on either the created key or the specified key.
  aws_kms_key_id = try(aws_kms_key.default[0].id, var.vault_aws_kms_key_id)

  # Set the key arn, based on either the created key or the specified key.
  aws_kms_key_arn = try(aws_kms_key.default[0].arn, data.aws_kms_key.default[0].arn)

  # Calculate the amount of instances in the ASG. A user can (partially) overrule this by setting `var.amount`.
  # Because of the complexity, here a bit of a break up of the components.
  #
  # `index` returns the first field that matches an argument. (`true` in this example.)
  # `floor` returns the rounded-down number.
  # `length` returns the amount of items in a list.
  # `try` returns the first result that does not produce an error. In this case, the number of availability zones can be less than 3. In that case, spin up 3 instances anyway.
  # So basically:
  # - If replication is enabled, deploy 5 machines, no matter what. (https://developer.hashicorp.com/vault/docs/internals/integrated-storage#minimums-scaling)
  # - Use the `var.amount`. (If specified.)
  # - Or use 5 for "large" regions. (5 or more availability zones)
  # - Or use 3 for "small" regions. (3 or less availability zones)
  #
  amount = var.vault_allow_replication ? 5 : var.vault_node_amount != null ? var.vault_node_amount : try(index([floor(length(data.aws_availability_zones.default.names) / 5) >= 1, floor(length(data.aws_availability_zones.default.names) / 3) >= 1], true) == 0 ? 5 : 3, 3)

  # Compose the package name based on the `vault_type`.
  _vault_package = {
    enterprise = "vault-enterprise-${var.vault_version}+ent-1"
    opensource = "vault-${var.vault_version}"
  }
  vault_package = local._vault_package[var.vault_type]

  # The cpu_manufacurer map to the ami pattern.
  _ami_pattern = {
    default             = "amzn2-ami-hvm-*-x86_64-ebs"
    amazon-web-services = "amzn2-ami-hvm-*-arm64-gp2"
  }
  ami_pattern = try(local._ami_pattern[var.vault_asg_cpu_manufacturer], local._ami_pattern["default"])

  # A map of disks, if `var.vault_audit_device` is disabled, this list is used.
  disks_without_audit = [
    {
      device_name = "/dev/sda1"
      ebs = {
        encrypted   = true
        iops        = contains(["gp2", "gp3"], local.volume_type) ? null : local.volume_iops
        volume_size = local.volume_size
        volume_type = local.volume_type
      }
    }
  ]

  # A map of disks, if `var.vault_audit_device` is enabled, this list is used.
  disks_with_audit = [
    {
      device_name = "/dev/sda1"
      ebs = {
        encrypted   = true
        iops        = contains(["gp2", "gp3"], local.volume_type) ? null : local.volume_iops
        volume_size = local.volume_size
        volume_type = local.volume_type
      }
    },
    {
      device_name = "/dev/sdb"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.vault_audit_device_size
        volume_type           = "gp3"
      }
    }
  ]
}
