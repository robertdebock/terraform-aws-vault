# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = var.domain
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = var.owner
  }
}

# Lookup DNS zone.
data "aws_route53_zone" "default" {
  name = var.domain
}

# Add validation details to the DNS zone.
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.default.zone_id
}

# Call the module.
module "vault" {
  source                    = "../../"
  vault_allow_ssh           = true
  vault_api_addr            = "https://${var.vault-name}.${var.domain}:8200"
  vault_audit_device        = true
  vault_aws_certificate_arn = aws_acm_certificate.default.arn
  vault_default_lease_time  = "24h"
  vault_keyfile_path        = "id_rsa.pub"
  vault_log_level           = "debug"
  vault_max_lease_time      = "168h"
  vault_name                = var.vault-name
  vault_size                = "development"
  vault_tags = {
    owner = var.owner
  }
}

# Add a loadbalancer record to DNS zone.
resource "aws_route53_record" "default" {
  name    = var.vault-name
  type    = "CNAME"
  ttl     = 300
  records = [module.vault.aws_lb_dns_name]
  zone_id = data.aws_route53_zone.default.id
}
