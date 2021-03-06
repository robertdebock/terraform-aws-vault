# Emulate an exising key pair, outside of the module.
resource "aws_key_pair" "default" {
  key_name   = "custom"
  public_key = file("id_rsa.pub")
}

# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "custom.robertdebock.nl"
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
  api_addr                    = "https://custom.robertdebock.nl"
  api_port                    = 443
  aws_lb_internal             = true
  certificate_arn             = aws_acm_certificate.default.arn
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.default.id
  name                        = "cstm"
  prometheus_disable_hostname = true
  prometheus_retention_time   = "30m"
  size                        = "custom"
  source                      = "../../"
  volume_iops                 = "3200"
  volume_size                 = "64"
  volume_type                 = "io1"
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "custom"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}
