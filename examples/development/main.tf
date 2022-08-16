# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "dev.robertdebock.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "robertdebock"
  }
}

# Lookup DNS zone.
data "cloudflare_zone" "default" {
  name = "robertdebock.nl"
}

# Add validation details to the DNS zone.
resource "cloudflare_record" "validation" {
  name    = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_name
  type    = "CNAME"
  value   = regex(".*[^.]", tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_value)
  zone_id = data.cloudflare_zone.default.id
}

# Call the module.
module "vault" {
  allow_ssh         = true
  api_addr          = "https://dev.robertdebock.nl:8200"
  certificate_arn   = aws_acm_certificate.default.arn
  default_lease_ttl = "24h"
  key_filename      = "id_rsa.pub"
  log_level         = "debug"
  max_lease_ttl     = "168h"
  name              = "dvlpm"
  size              = "development"
  source            = "../../"
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "dev"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}
