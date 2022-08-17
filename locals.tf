locals {

  # Resolve the ip_addr, either set using `api_addr` or the created resource.
  api_addr = coalesce(var.api_addr, "https://${aws_lb.api.dns_name}:${var.api_port}")

  # Combine the variable `tags` with specific prefixes.
  tags             = merge({ Name = "${var.name}-${random_string.default.result}" }, var.tags)
  bastion_tags     = merge({ Name = "bastion-${var.name}-${random_string.default.result}" }, var.tags)
  private_tags     = merge({ Name = "private-${var.name}-${random_string.default.result}" }, var.tags)
  public_tags      = merge({ Name = "public-${var.name}-${random_string.default.result}" }, var.tags)
  api_tags         = merge({ Name = "api-${var.name}-${random_string.default.result}" }, var.tags)
  replication_tags = merge({ Name = "replication-${var.name}-${random_string.default.result}" }, var.tags)

  # Compose the name of the instances.
  instance_name = "vault-${var.name}-${random_string.default.result}"

  # Combine api arn and (optionally) replication arn.
  target_group_arns = compact([aws_lb_target_group.api.arn, try(aws_lb_target_group.replication[0].arn, null)])

  # A map from `size` to `instance_type`.
  _instance_type = {
    custom      = var.instance_type
    development = "t4g.nano"
    minimum     = "m5.large"
    small       = "m5.xlarge"
    large       = "m5.2xlarge"
    maximum     = "m5.4xlarge"
  }
  instance_type = local._instance_type[var.size]

  # A map from `size` to `volume_type`.
  _volume_type = {
    custom      = var.volume_type
    development = "gp2"
    minimum     = "gp3"
    small       = "gp3"
    large       = "gp3"
    maximum     = "gp3"
  }
  volume_type = local._volume_type[var.size]

  # A map from `size` to `volume_size`.
  _volume_size = {
    custom      = var.volume_size
    development = 8
    minimum     = 100
    small       = 100
    large       = 200
    maximum     = 200
  }
  volume_size = local._volume_size[var.size]

  # A map from `size` to `volume_iops`.
  _volume_iops = {
    custom      = var.volume_iops
    development = 0
    minimum     = 3000
    small       = 3000
    large       = 10000
    maximum     = 10000
  }
  volume_iops = local._volume_iops[var.size]

  # Resolve the key, either set using `key_name` or placed using `key_filename`.
  key_name = try(aws_key_pair.default[0].id, var.key_name)

  # Form the cidr_block based on a variable.
  cidr_block = "${var.vpc_cidr_block_start}.0.0/16"

  # Select the vpc_id, either created or set as a variable.
  vpc_id = try(aws_vpc.default[0].id, var.vpc_id)

  # Select the private_subnet_ids, either set as a variable or created.
  private_subnet_ids = coalescelist(var.private_subnet_ids, aws_subnet.private[*].id)

  # Select the public_subnet_ids, either created or set as a variable.
  public_subnet_ids = coalescelist(var.public_subnet_ids, aws_subnet.public[*].id)

  # Select the gateway_id, either the created resource or the found resource.
  gateway_id = try(aws_internet_gateway.default[0].id, data.aws_internet_gateway.default[0].id)

  # Set the key id, based on either the created key or the specified key.
  aws_kms_key_id = try(aws_kms_key.default[0].id, var.aws_kms_key_id)

  # Set the key arn, based on either the created key or the specified key.
  aws_kms_key_arn = try(aws_kms_key.default[0].arn, data.aws_kms_key.default[0].arn)

  # Calculate the amount of instances in the ASG. A user can overrule this by setting `var.amount`.
  # Because of the complexity, here a bit of a break up of the components.
  #
  # `index` returns the first field that matches an argument. (`true` in this example.)
  # `floor` returns the rounded-down number.
  # `length` returns the amount of items in a list.
  # `try` returns the first result that does not produce an error. In this case, the number of availability zones can be less than 3. In that case, spin up 3 instances anyway.
  # So basically:
  # - Either use the `var.amount`. (If specified.)
  # - Or use 5 for "large" regions. (5 or more availability zones)
  # - Or use 3 for "small" regions. (3 or less availability zones)
  amount = var.amount != null ? var.amount : try(index([floor(length(data.aws_availability_zones.default)/5) >= 1, floor(length(data.aws_availability_zones.default)/3) >=1], true) == 0 ? 5 : 3, 3)

  # Compose the package name based on the `vault_type`.
  _vault_package = {
    enterprise = "vault-enterprise-${var.vault_version}+ent-1"
    opensource = "vault-${var.vault_version}"
  }
  vault_package = local._vault_package[var.vault_type]

  # The instance_type can be of the type "x86_64" or "arm64". This mapping sets the correct pattern to find an ami.
  _ami_pattern = {
    default = "amzn2-ami-hvm-*-x86_64-ebs"
    c6g     = "amzn2-ami-hvm-*-arm64-gp2"
    c6gd    = "amzn2-ami-hvm-*-arm64-gp2"
    c6gn    = "amzn2-ami-hvm-*-arm64-gp2"
    g5g     = "amzn2-ami-hvm-*-arm64-gp2"
    im4gn   = "amzn2-ami-hvm-*-arm64-gp2"
    is4gen  = "amzn2-ami-hvm-*-arm64-gp2"
    m6g     = "amzn2-ami-hvm-*-arm64-gp2"
    m6gd    = "amzn2-ami-hvm-*-arm64-gp2"
    r6g     = "amzn2-ami-hvm-*-arm64-gp2"
    r6gd    = "amzn2-ami-hvm-*-arm64-gp2"
    t4g     = "amzn2-ami-hvm-*-arm64-gp2"
    x2gd    = "amzn2-ami-hvm-*-arm64-gp2"
  }
  ami_pattern = try(local._ami_pattern[split(".", local.instance_type)[0]], local._ami_pattern["default"])

  # A map of disks, if `var.audit_device` is disabled, this list is used.
  disks_without_audit = [
    {
      device_name = "/dev/sda1"
      ebs = {
        encrypted   = true
        iops        = local.volume_iops
        volume_size = local.volume_size
        volume_type = local.volume_type
      }
    }
  ]

  # A map of disks, if `var.audit_device` is enabled, this list is used.
  disks_with_audit = [
    {
      device_name = "/dev/sda1"
      ebs = {
        encrypted   = true
        iops        = local.volume_iops
        volume_size = local.volume_size
        volume_type = local.volume_type
      }
    },
    {
      device_name = "/dev/sdb"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.audit_device_size
        volume_type           = "gp3" 
      }
    }
  ]
}
