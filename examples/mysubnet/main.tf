# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "mysubnet.robertdebock.nl"
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
  api_addr             = "https://mysubnet.robertdebock.nl:8200"
  certificate_arn      = aws_acm_certificate.default.arn
  key_filename         = "id_rsa.pub"
  name                 = "msbnt"
  source               = "../../"
  vpc_cidr_block_start = "192.168"
  vpc_id               = "vpc-05994ad2b54a07bfc"
  private_subnet_ids   = ["subnet-0b32bde1e5d573c7e", "subnet-04fd055f415c291a7", "subnet-09aad8548185eeafd"]
  public_subnet_ids    = ["subnet-07c5105014fe4459b", "subnet-005874fc39d0e373e", "subnet-07cdbe766847f6270"]
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "mysbt"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}
