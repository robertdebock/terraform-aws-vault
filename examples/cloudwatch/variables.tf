variable "domain" {
  default     = "meinit.nl"
  description = "The domain to use for the deployment. This domain should be hosted on AWS."
}

variable "region" {
  default     = "eu-west-1"
  description = "The region to use for the deployment."
}

variable "license" {
  description = "Vault Enterprise license"
}
