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
  private_subnet_ids   = ["subnet-0375587643ecc9f85", "subnet-06017ca11fe1c6000", "subnet-0512bc3a4bf85455a"]
  public_subnet_ids    = ["subnet-0f6578d991e7fc991", "subnet-05efa5fcce21b7caf", "subnet-06d1d0f490695c795"]
  vpc_id               = "vpc-06a33ce8f2b6352fa"
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
