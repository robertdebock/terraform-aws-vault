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
  api_addr           = "https://mysubnet.robertdebock.nl:8200"
  certificate_arn    = aws_acm_certificate.default.arn
  key_filename       = "id_rsa.pub"
  name               = "msbnt"
  source             = "../../"
  vpc_id             = "vpc-0d19743448d58cf32"
  private_subnet_ids = ["subnet-0a33e50c7a0be18ea", "subnet-098bf1b2d2e094d56", "subnet-0af19b51f8eb94c72"]
  public_subnet_ids  = ["subnet-0b1f745a844aa90ac", "subnet-02a85aa7ae69eed7e", "subnet-0d17079fb1f526a6e"]
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
