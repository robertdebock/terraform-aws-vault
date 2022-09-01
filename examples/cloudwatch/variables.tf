variable "name" {
  description = "The name of the vault cluster in 3 to 5 characters. Changes in runtime would re-deploy a new cluster, data from the old cluster would be lost."
  type        = string
  default     = "unset"
  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 5 && var.name != "default"
    error_message = "Please use a minimum of 3 and a maximum of 5 characters. \"default\" can't be used because it is reserved."
  }
}
variable "cloudflare_token" {
  description = "API token to use for cloudflare"
  type        = string
  default     = ""
  validation {
    condition     = var.cloudflare_token != ""
    error_message = "Cloudflare API token is not set."
  }
}
variable "owner" {
  description = "Name of the owner. Used for the AWS owner tag."
  type        = string
  default     = ""
  validation {
    condition     = var.owner != ""
    error_message = "Owner variable not set."
  }
}
variable "domain" {
  description = "Domain to be used for the Vault deployment."
  type        = string
  default     = ""
  validation {
    condition     = var.domain != ""
    error_message = "Variable for the domain is not set."
  }
}