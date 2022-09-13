# Read the prerequisites details.
data "terraform_remote_state" "default" {
  backend = "local"

  config = {
    path = "./prerequisites/terraform.tfstate"
  }
}

# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "mykey.meinit.nl"
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
  vault_api_addr            = "https://mykey.meinit.nl:8200"
  vault_aws_certificate_arn = aws_acm_certificate.default.arn
  vault_keyfile_path        = "id_rsa.pub"
  aws_kms_key_id            = data.terraform_remote_state.default.outputs.aws_kms_key_id
  vault_name                = "myky"
  source                    = "../../"
  vault_tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "aws_route53_record" "default" {
  name    = "mykey"
  type    = "CNAME"
  ttl     = 300
  records = [module.vault.aws_lb_dns_name]
  zone_id = data.aws_route53_zone.default.id
}
