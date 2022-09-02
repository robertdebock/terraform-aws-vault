# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "default.${var.domain}"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = var.owner
  }
}

# Lookup DNS zone.
data "cloudflare_zone" "default" {
  name = var.domain
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
  certificate_arn  = aws_acm_certificate.default.arn
  name             = "watch"
  source           = "../../"
  key_filename     = "id_rsa.pub"
  cloudwatch_agent = true
  tags = {
    owner = var.owner
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "default"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}