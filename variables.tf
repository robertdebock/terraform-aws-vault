# You can overwrite the default values for the variables below, typically
# variable values are set when calling the module. See on of the `examples/`.

variable "name" {
  description = "The name of the vault cluster in 3 to 5 characters. Changes in runtime would re-deploy a new cluster, data from the old cluster would be lost."
  type        = string
  default     = "unset"
  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 5 && var.name != "default"
    error_message = "Please use a minimum of 3 and a maximum of 5 characters. \"default\" can't be used because it is reserved."
  }
}

variable "vault_version" {
  description = "The version of Vault to install."
  type        = string
  default     = "1.11.2"
  validation {
    condition     = can(regex("^1\\.", var.vault_version))
    error_message = "Please use a SemVer version, where the major version is \"1\". Use \"1.2.7\" or newer."
  }
}

variable "key_name" {
  description = "The name of an existing ssh key. Either specify \"key_name\" or \"key_filename\"."
  type        = string
  default     = ""
}

variable "key_filename" {
  description = "The name of the file that has the public ssh key stored. Either specify \"key_name\" or \"key_filename\"."
  type        = string
  default     = ""
  validation {
    condition     = try((var.key_filename != "" && fileexists(var.key_filename)), var.key_filename == "")
    error_message = "The specified certificate file does not exist."
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

variable "volume_type" {
  description = "When `size` is set to `custom`, specify your own volume type here."
  type        = string
  default     = "io1"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.volume_type)
    error_message = "Please use \"gp3\", \"gp3\", \"io1\" or \"io2\"."
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
  default     = 400
  validation {
    condition     = var.volume_iops >= 0
    error_message = "Please us a positive number, such as \"2500\"."
  }
}

variable "amount" {
  description = "The amount of instances to deploy, by not specifying the value, the optimum amount is calculated."
  type        = number
  default     = null
  validation {
    condition     = var.amount == null ? true : var.amount % 2 == 1 && var.amount >= 3 && var.amount <= 5
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

# TODO: This feels cluncky, try to calculate the cidr block.
variable "vpc_cidr_block_start" {
  description = "The first two octets of the VPC cidr."
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
  default     = 0
  validation {
    condition     = var.max_instance_lifetime == 0 || (var.max_instance_lifetime >= 86400 && var.max_instance_lifetime <= 31536000)
    error_message = "Use \"0\" to remove the parameter or a value between \"86400\" and \"31536000\"."
  }
}

variable "certificate_arn" {
  description = "The ARN to an existing certificate."
  type        = string
}

variable "log_level" {
  description = "Specifies the Vault log level to use."
  type        = string
  default     = "info"
  validation {
    condition     = contains(["trace", "debug", "error", "warn", "info"], var.log_level)
    error_message = "Please use \"trace\", \"debug\", \"error\", \"warn\" or \"info\"."
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
    condition     = can(regex("^[1-9][0-9]*(s|m|h)$", var.max_lease_ttl))
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

variable "private_subnet_ids" {
  description = "The ids of the private subnets to deploy to. These subnets should have a NAT gateway. Only required when `vpc_id` is set."
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "The ids of the private subnets to deploy to. These subnets should have in internet gateway. ßOnly required when `vpc_id` is set."
  type        = list(string)
  default     = []
}

variable "vault_type" {
  description = "The type of installation to do, either \"enterprise\" or \"opensource\"."
  type        = string
  default     = "opensource"
  validation {
    condition     = contains(["enterprise", "opensource"], var.vault_type)
    error_message = "Please use \"enterprise\" or \"opensource\"."
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

variable "api_addr" {
  description = "The URL for the Vault API to advertise."
  type        = string
  default     = ""
  validation {
    condition     = can(regex("^http", var.api_addr)) || length(var.api_addr) == 0
    error_message = "Please use a URL like: \"https://vault.example.com:8200\"."
  }
}

variable "allowed_cidr_blocks_replication" {
  description = "What CIDR blocks are allowed to replicate."
  type        = list(string)
  default     = []
}

variable "cooldown" {
  description = "The cooldown period in seconds to use for the autoscaling group."
  type        = number
  default     = 300
  validation {
    condition     = var.cooldown >= 120 && var.cooldown <= 600
    error_message = "Please use a cooldown period between 120 and 600 seconds."
  }
}

variable "vault_ca_cert" {
  description = "The CA certificate that Vault nodes will use to sign their certificate."
  type        = string
  default     = "tls/vault_ca.crt"
  validation {
    condition     = fileexists(var.vault_ca_cert)
    error_message = "The specified certificate file does not exist."
  }
}

variable "vault_ca_key" {
  description = "The CA key that Vault nodes will use to sign their certificate."
  type        = string
  default     = "tls/vault_ca.pem"
  validation {
    condition     = fileexists(var.vault_ca_key)
    error_message = "The specified key file does not exist."
  }
}

variable "vault_replication" {
  description = "Allow Vault replication to be used."
  type        = bool
  default     = false
}

variable "telemetry" {
  description = "Enable telemetry; uses a weaker health check on the ASG."
  type        = bool
  default     = false
}

variable "prometheus_retention_time" {
  description = "Specifies the amount of time that Prometheus metrics are retained in memory."
  type        = string
  default     = "24h"
  validation {
    condition     = try(can(regex("^[1-9][0-9]*(s|m|h)$", var.prometheus_retention_time)), var.prometheus_retention_time == 0)
    error_message = "Please use time indicator, starting with a number, ending in s, m or h. 0 can also be used to disable retention."
  }
}
variable "prometheus_disable_hostname" {
  description = "It is recommended to also enable the option disable_hostname to avoid having prefixed metrics with hostname."
  type        = bool
  default     = false
}

variable "telemetry_unauthenticated_metrics_access" {
  description = "If set to true, allows unauthenticated access to the /v1/sys/metrics endpoint."
  type        = bool
  default     = false
}

variable "aws_kms_key_id" {
  description = "You can optionally bring your own AWS KMS key."
  type        = string
  default     = ""
}

variable "warmup" {
  description = "The warm period in seconds to use for the autoscaling group and health check."
  type        = number
  default     = 300
  validation {
    condition     = var.warmup >= 60 && var.warmup <= 600
    error_message = "Please use a warmup period between 60 and 600 seconds."
  }
}

variable "api_port" {
  description = "The TCP port where the API should listen."
  type        = number
  default     = 8200
  validation {
    condition     = var.api_port >= 1 && var.api_port <= 65535
    error_message = "Please choose a port number between 1 and 65535."
  }
}

variable "replication_port" {
  description = "The TCP port where replication should listen."
  type        = number
  default     = 8201
  validation {
    condition     = var.replication_port >= 1 && var.replication_port <= 65535
    error_message = "Please choose a port number between 1 and 65535."
  }
}

variable "vault_aws_s3_snapshots_bucket" {
  description = "Specify an AWS S3 bucket to store snapshots in."
  type        = string
  default     = ""
  validation {
    condition     = (length(var.vault_aws_s3_snapshots_bucket) >= 3 && length(var.vault_aws_s3_snapshots_bucket) <= 63) || var.vault_aws_s3_snapshots_bucket == ""
    error_message = "Please use a bucket name between 3 and 63 characters."
  }
}

variable "aws_lb_internal" {
  description = "Specify if the loadbalancer is exposed to the internet or not."
  type        = bool
  default     = false
}

variable "extra_security_group_ids" {
  description = "Specify the security group ids that should also have access to Vault."
  type        = list(string)
  default     = []
}

variable "advanced_monitoing" {
  description = "Specify of the instances will use advanced monitoring. Makes graphs update more frequently, comes at a price."
  type        = bool
  default     = true
}

variable "audit_device" {
  description = "You can specify an audit device to be created. This will create a mount on the Vault nodes."
  type        = bool
  default     = false
}

variable "audit_device_size" {
  description = "The size (in GB) of the audit device when `var.audit_device` is enabled."
  type        = number
  default     = 32
  validation {
    condition     = var.audit_device_size >= 16
    error_message = "Please use 16 (GB) or more."
  }
}

variable "audit_device_path" {
  description = "The absolute pah to where Vault can store audit logs."
  type        = string
  default     = "/var/log/vault"
  validation {
    condition     = can(regex("^/", var.audit_device_path))
    error_message = "Please specify an absolute path."
  }
}

variable "allow_ssh" {
  description = "You can (dis-) allow SSH access to the Vault nodes."
  type        = bool
  default     = false
}

variable "minimum_memory" {
  description = "When using a custom size, the minimum amount of memoroy (in megabytes) can be set."
  type        = number
  default     = 8192
  validation {
    condition     = var.minimum_memory >= 512
    error_message = "Please use 512 or more."
  }
}

variable "minimum_vcpus" {
  description = "When using a custom size, the minimum amount of vcpus can be set."
  type        = number
  default     = 2
}

variable "cpu_manufacturer" {
  description = "You can choose the cpu manufacturer."
  type        = string
  default     = "amazon-web-services"
  validation {
    condition     = contains(["amazon-web-services", "amd", "intel"], var.cpu_manufacturer)
    error_message = "Please choosse from \"amazon-web-services\", \"amd\" or \"intel\"."
  }
}

variable "cloudwatch_agent" {
  description = "When true, installs the AWS Cloudwatch agent on the Vault nodes."
  type = bool
  default = false
}