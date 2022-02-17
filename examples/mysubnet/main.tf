# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name       = "mysubnet.robertdebock.nl"
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
  certificate_arn = aws_acm_certificate.default.arn
  key_filename    = "id_rsa.pub"
  name            = "mysubnet"
  source          = "../../"
  vpc_id          = "vpc-0e408fb19cdf19c29"
  subnet_ids      = ["subnet-057032f1178cad01e", "subnet-0965fe1a3ce6953fc", "subnet-0ae980fe642e14861"]
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "mysubnet"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}
