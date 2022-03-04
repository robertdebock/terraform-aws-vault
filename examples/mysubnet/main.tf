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
  api_addr        = "https://mysubnet.robertdebock.nl:8200"
  certificate_arn = aws_acm_certificate.default.arn
  key_filename    = "id_rsa.pub"
  name            = "msbnt"
  source          = "../../"
  vpc_id          = "vpc-0ceae91a773a43365"
  subnet_ids      = ["subnet-01faa9046b9f58749", "subnet-0af54b5d0832d4f42", "subnet-0f9e5a02098bda2c2"]
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
