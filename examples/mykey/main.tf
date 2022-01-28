# Emulate an exising key pair, outside of the module.
resource "aws_key_pair" "default" {
  key_name   = "mykey"
  public_key = file("id_rsa.pub")
}

# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name       = "mykey.robertdebock.nl"
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
  zone_id = data.cloudflare_zone.default.id
  name    = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_name
  value   = regex(".*[^.]", tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_value)
  type    = "CNAME"
}

# Call the module.
module "vault" {
  source          = "../../"
  name            = "vltp"
  certificate_arn = aws_acm_certificate.default.arn
  key_id          = aws_key_pair.default.id
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  zone_id = data.cloudflare_zone.default.id
  name    = "vault"
  value   = module.vault.aws_lb_dns_name
  type    = "CNAME"
}
