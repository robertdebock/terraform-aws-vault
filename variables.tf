variable "name" {
  description = "The name of the vault cluster in 3 to 8 characters."
  type        = string
  default     = "vault"
  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 8 && var.name != "default"
    error_message = "Please use a minimum of 3 and a maximum of 8 characters. \"default\" can't be used because it is reserved."
  }
}

variable "vault_version" {
  description = "The version of Vault to install."
  type        = string
  default     = "1.8.4"
  validation {
    condition     = can(regex("^1\\.", var.vault_version))
    error_message = "Please use a SemVer version, where the major version is \"1\"."
  }
}

variable "key_filename" {
  description = "The name of the file that has the public ssh key stored."
  default     = "id_rsa.pub"
}

variable "region" {
  description = "The region to deploy to."
  type        = string
  default     = "eu-central-1"
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
    condition     = contains(["development", "minimum", "small", "large", "maximum"], var.size)
    error_message = "Please use \"development\", \"minimum\", \"small\", \"large\" or \"maximum\"."
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

variable "vpc_id" {
  description = "The VPC identifier to deploy in. Fill this value when you want the Vault installation to be done in an existing VPC."
  type        = string
  default     = ""
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

variable "launch_configuration_version" {
  description = "The launch configuration version."
  type        = number
  default     = 1
  validation {
    condition     = var.launch_configuration_version >= 0
    error_message = "Please use a positive number, like \"1\" or \"23\"."
  }
}
