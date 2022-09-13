# Emulate an exising key pair, outside of the module.
resource "aws_key_pair" "default" {
  key_name   = "custom"
  public_key = file("id_rsa.pub")
}

# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "custom.meinit.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "robertdebock"
  }
}

# Lookup DNS zone.
data "aws_route53_zone" "default" {
  name = "meinit.nl"
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
  allow_ssh                   = true
  api_addr                    = "https://custom.meinit.nl"
  api_port                    = 443
  audit_device                = true
  audit_device_size           = 16
  aws_lb_internal             = false
  certificate_arn             = aws_acm_certificate.default.arn
  cpu_manufacturer            = "intel"
  vault_aws_key_name          = aws_key_pair.default.key_name
  minimum_vcpus               = 2
  minimum_memory              = 1024
  vault_name                  = "cstm"
  prometheus_disable_hostname = true
  prometheus_retention_time   = "30m"
  size                        = "custom"
  source                      = "../../"
  volume_iops                 = 3200
  volume_size                 = 64
  volume_type                 = "io1"
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "aws_route53_record" "default" {
  name    = "custom"
  type    = "CNAME"
  ttl     = 300
  records = [module.vault.aws_lb_dns_name]
  zone_id = data.aws_route53_zone.default.id
}
