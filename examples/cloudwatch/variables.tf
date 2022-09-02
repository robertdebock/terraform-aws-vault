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