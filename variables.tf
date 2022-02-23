variable "name" {
  description = "The name of the vault cluster in 3 to 5 characters."
  type        = string
  default     = "vault"
  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 5 && var.name != "default"
    error_message = "Please use a minimum of 3 and a maximum of 5 characters. \"default\" can't be used because it is reserved."
  }
}

variable "vault_version" {
  description = "The version of Vault to install."
  type        = string
  default     = "1.9.3"
  validation {
    condition     = can(regex("^1\\.", var.vault_version))
    error_message = "Please use a SemVer version, where the major version is \"1\". Use \"1.2.7\" or newer."
  }
}

variable "key_name" {
  description = "The name of an existing ssh key. Either specify \"key_name\" or \"key_filename\"."
  default     = ""
}

variable "key_filename" {
  description = "The name of the file that has the public ssh key stored. Either specify \"key_name\" or \"key_filename\"."
  default     = ""
}

variable "region" {
  description = "The region to deploy to."
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = contains(["eu-central-1", "eu-north-1", "eu-south-1", "eu-west-1", "eu-west-2", "eu-west-3", ], var.region)
    error_message = "Please use \"eu-central-1\", \"eu-north-1\", \"eu-south-1\", \"eu-west-1\", \"eu-west-2\" or \"eu-west-3\"."
  }
}

variable "size" {
  description = "The size of the deployment."
  type        = string
  default     = "small"
  validation {
    condition     = contains(["custom", "development", "minimum", "small", "large", "maximum"], var.size)
    error_message = "Please use \"custom\", \"development\", \"minimum\", \"small\", \"large\" or \"maximum\"."
  }
}

variable "instance_type" {
  description = "When `size` is set to `custom`, specify your own instance type here."
  type        = string
  default     = "t3.large"
}

variable "volume_type" {
  description = "When `size` is set to `custom`, specify your own volume type here."
  type        = string
  default     = "io1"
  validation {
    condition     = contains(["gp2", "io1"], var.volume_type)
    error_message = "Please use \"gp2\" or \"io1\"."
  }
}
variable "volume_size" {
  description = "When `size` is set to `custom`, specify your own volume size (in GB) here."
  type        = number
  default     = 50
  validation {
    condition     = var.volume_size > 8
    error_message = "Please use a minimum of \"8\"."
  }
}

variable "volume_iops" {
  description = "When `size` is set to `custom`, specify your own volume iops here. (Maximum 50 times the `volume_size`.)"
  type        = number
  default     = "400"
  validation {
    condition     = var.volume_iops >= 0
    error_message = "Please us a positive number, such as \"2500\"."
  }
}

variable "amount" {
  description = "The amount of instances to deploy."
  type        = number
  default     = 3
  validation {
    condition     = var.amount % 2 == 1 && var.amount >= 3 && var.amount <= 5
    error_message = "Please use an odd number for amount, like 3 or 5."
  }
}

variable "vault_ui" {
  description = "Expose (or hide) a web user interface."
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "What CIDR blocks are allowed to access Vault."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_id" {
  description = "The VPC identifier to deploy in. Fill this value when you want the Vault installation to be done in an existing VPC."
  type        = string
  default     = ""
}

variable "bastion_host" {
  description = "A bastion host is optional and would allow you to login to the instances."
  type        = bool
  default     = true
}

variable "aws_vpc_cidr_block_start" {
  description = "The first two octets of the VPC cidr. Only required when `vpc_id` is set to \"\"."
  type        = string
  default     = "172.16"
}

variable "tags" {
  description = "Tags to add to resources."
  type        = map(string)
  default = {
    owner = "unset"
  }
}

variable "max_instance_lifetime" {
  description = "The amount of seconds after which to replace the instances."
  type        = number
  default     = 86400
  validation {
    condition     = var.max_instance_lifetime == 0 || (var.max_instance_lifetime >= 86400 && var.max_instance_lifetime <= 31536000)
    error_message = "Use \"0\" to remove the parameter or a value between \"86400\" and \"31536000\"."
  }
}

variable "certificate_arn" {
  description = "The ARN to an existing certificate."
  type        = string
}

variable "spot_price" {
  description = "The price to offer for a spot instance. Only required when `size` is set to `development`."
  type        = number
  default     = 0.024
  validation {
    condition     = var.spot_price >= 0.0036
    error_message = "Please use a minimum spot price of 0.0036."
  }
}

variable "log_level" {
  description = "Specifies the Vault log level to use."
  type        = string
  default     = "Info"
  validation {
    condition     = contains(["Trace", "Debug", "Error", "Warn", "Info"], var.log_level)
    error_message = "Please use \"Trace\", \"Debug\", \"Error\", \"Warn\" or \"Info\"."
  }
}

variable "default_lease_ttl" {
  description = "Specifies the default lease duration for tokens and secrets."
  type        = string
  default     = "768h"
  validation {
    condition     = can(regex("^[1-9][0-9]*(s|m|h)", var.default_lease_ttl))
    error_message = "Please use a positive number, followed by the duration indicator."
  }
}

variable "max_lease_ttl" {
  description = "Specifies the maximum lease duration for tokens and secrets."
  type        = string
  default     = "768h"
  validation {
    condition     = can(regex("^[1-9][0-9]*(s|m|h)", var.max_lease_ttl))
    error_message = "Please use a positive number, followed by the duration indicator."
  }
}

variable "vault_path" {
  description = "The absolute path where Vault should place data."
  type        = string
  default     = "/opt/vault"
  validation {
    condition     = can(regex("^/", var.vault_path))
    error_message = "Please use an absolute path like \"/my/vault\"."
  }
}

variable "subnet_ids" {
  description = "The ids of the subnets to deploy to."
  type        = list(string)
  default     = []
}

variable "vault_type" {
  description = "The type of installation to do, either \"enterprise\" or \"opensource\"."
  type        = string
  default     = "opensource"
  validation {
    condition     = contains(["enterprise", "hsm", "opensource"], var.vault_type)
    error_message = "Please use \"enterprise\", \"hsm\" or \"opensource\"."
  }
}

variable "vault_license" {
  description = "The contents of the license."
  type        = string
  default     = ""
  validation {
    condition     = length(var.vault_license) == 1201 || length(var.vault_license) == 0
    error_message = "The license should contain 1201 characters."
  }
}
