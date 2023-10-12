variable "domain" {
  default     = "meinit.nl"
  description = "The domain to use for the deployment. This domain should be hosted on AWS."
}
variable "owner" {
  default     = "no owner set"
  description = "Owner of the deployed AWS resources."
}
variable "vault-name" {
  default     = "vault"
  description = "Name of the Vault deployment. Together with the domain it creates the FQDN."
}
