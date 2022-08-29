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
  type = string
  default = ""
  validation {
    condition = var.cloudflare_token != ""
    error_message = "Cloudflare API token is not set."
  }
}