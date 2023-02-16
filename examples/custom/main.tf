# Read the prerequisites details.
data "terraform_remote_state" "default" {
  backend = "local"
  config = {
    path = "./prerequisites/terraform.tfstate"
  }
}

# Emulate an exising key pair, outside of the module.
resource "aws_key_pair" "default" {
  key_name   = "custom"
  public_key = file("id_rsa.pub")
}

# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "custom.${var.domain}"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "Robert de Bock"
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
  source                                    = "../../"
  vault_allow_ssh                           = true
  vault_api_addr                            = "https://custom.${var.domain}"
  vault_api_port                            = 443
  vault_asg_cpu_manufacturer                = "amazon-web-services"
  vault_asg_instance_lifetime               = 604800
  vault_asg_minimum_required_memory         = 1024
  vault_asg_minimum_required_vcpus          = 2
  vault_aws_certificate_arn                 = aws_acm_certificate.default.arn
  vault_aws_key_name                        = aws_key_pair.default.key_name
  vault_aws_lb_availability                 = "internal"
  vault_custom_script_s3_url                = data.terraform_remote_state.default.outputs.vault_custom_script_s3_url
  vault_custom_script_s3_bucket_arn         = data.terraform_remote_state.default.outputs.custom_script_s3_bucket_arn
  vault_bastion_custom_script_s3_url        = data.terraform_remote_state.default.outputs.vault_bastion_custom_script_s3_url
  vault_bastion_custom_script_s3_bucket_arn = data.terraform_remote_state.default.outputs.custom_script_s3_bucket_arn
  vault_bastion_public_ip                   = false
  vault_extra_security_group_ids            = data.terraform_remote_state.default.outputs.security_group_ids
  vault_name                                = "cstm"
  vault_prometheus_disable_hostname         = true
  vault_prometheus_retention_time           = "30m"
  vault_private_subnet_ids                  = data.terraform_remote_state.default.outputs.private_subnet_ids
  vault_public_subnet_ids                   = data.terraform_remote_state.default.outputs.public_subnet_ids
  vault_size                                = "custom"
  vault_volume_size                         = 64
  vault_volume_type                         = "gp2"
  vault_vpc_cidr_block_start                = "10.70"
  vault_aws_vpc_id                          = data.terraform_remote_state.default.outputs.vpc_id
  vault_tags = {
    owner = "Robert de Bock"
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
