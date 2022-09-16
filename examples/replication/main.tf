# Read the prerequisites details.
data "terraform_remote_state" "default" {
  backend = "local"

  config = {
    path = "./prerequisites/terraform.tfstate"
  }
}

# Make a certificate for EU.
resource "aws_acm_certificate" "default_eu" {
  count       = 2
  domain_name = "vault-eu-${count.index}.meinit.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  provider    = aws.eu-west-1
  validation_method = "DNS"
  tags = {
    owner = "Robert de Bock"
  }
}

# Make a certificate for US.
resource "aws_acm_certificate" "default_us" {
  count       = 2
  domain_name = "vault-us-${count.index}.meinit.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "Robert de Bock"
  }
}

# Lookup DNS zone.
data "aws_route53_zone" "default" {
  name = "meinit.nl"
}

# Add validation details to the DNS zone.
resource "aws_route53_record" "validation_eu_0" {
  for_each = {
    for dvo in aws_acm_certificate.default_eu[0].domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "validation_eu_1" {
  for_each = {
    for dvo in aws_acm_certificate.default_eu[1].domain_validation_options : dvo.domain_name => {
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


# Add validation details to the DNS zone.
resource "aws_route53_record" "validation_us_0" {
  for_each = {
    for dvo in aws_acm_certificate.default_us[0].domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "validation_us_1" {
  for_each = {
    for dvo in aws_acm_certificate.default_us[1].domain_validation_options : dvo.domain_name => {
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

module "vault_eu" {
  count = length(aws_acm_certificate.default_eu)
  providers = {
    aws = aws.eu-west-1
  }
  source                                = "../../"
  vault_allow_replication               = true
  vault_allow_ssh                       = true
  vault_allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  vault_api_addr                        = "https://vault-eu-${count.index}.meinit.nl:8200"
  vault_aws_certificate_arn             = aws_acm_certificate.default_eu[count.index].arn
  vault_aws_kms_key_id                  = data.terraform_remote_state.default.outputs.aws_kms_key_id_eu
  vault_aws_vpc_id                      = data.terraform_remote_state.default.outputs.vpc_id_eu
  vault_create_bastionhost              = count.index == 0 ? true : false
  vault_keyfile_path                    = "id_rsa.pub"
  vault_license                         = "OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFU"
  vault_name                            = "veu-${count.index}"
  vault_private_subnet_ids              = data.terraform_remote_state.default.outputs.private_subnet_ids_eu
  vault_public_subnet_ids               = data.terraform_remote_state.default.outputs.public_subnet_ids_eu
  vault_size                            = "minimum"
  vault_type                            = "enterprise"
  vault_vpc_cidr_block_start            = "10.1"
  vault_tags = {
    owner = "Robert de Bock"
  }
}

# Call the module.
module "vault_us" {
  count                                 = length(aws_acm_certificate.default_us)
  source                                = "../../"
  vault_allow_replication               = true
  vault_allow_ssh                       = true
  vault_allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  vault_api_addr                        = "https://vault-us-${count.index}.meinit.nl:8200"
  vault_aws_certificate_arn             = aws_acm_certificate.default_us[count.index].arn
  vault_aws_kms_key_id                  = data.terraform_remote_state.default.outputs.aws_kms_key_id_us
  vault_aws_vpc_id                      = data.terraform_remote_state.default.outputs.vpc_id_us
  vault_create_bastionhost              = count.index == 0 ? true : false
  vault_keyfile_path                    = "id_rsa.pub"
  vault_license                         = "OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFUSCATED_BY_DESIGN_OBFU"
  vault_name                            = "vus-${count.index}"
  vault_private_subnet_ids              = data.terraform_remote_state.default.outputs.private_subnet_ids_us
  vault_public_subnet_ids               = data.terraform_remote_state.default.outputs.public_subnet_ids_us
  vault_size                            = "minimum"
  vault_type                            = "enterprise"
  vault_vpc_cidr_block_start            = "10.0"
  vault_tags = {
    owner = "Robert de Bock"
  }
}

# Add a load balancer record for the api to DNS zone.
resource "aws_route53_record" "api_eu" {
  count   = length(aws_acm_certificate.default_eu)
  name    = "vault-eu-${count.index}"
  records = [module.vault_eu[count.index].aws_lb_dns_name]
  ttl     = 300
  type    = "CNAME"
  zone_id = data.aws_route53_zone.default.id
}

# Add a load balancer record for the api to DNS zone.
resource "aws_route53_record" "api_us" {
  count   = length(aws_acm_certificate.default_us)
  name    = "vault-us-${count.index}"
  records = [module.vault_us[count.index].aws_lb_dns_name]
  ttl     = 300
  type    = "CNAME"
  zone_id = data.aws_route53_zone.default.id
}

# Add a load balancer record for replication to DNS zone.
resource "aws_route53_record" "replication_eu" {
  count   = length(aws_acm_certificate.default_eu)
  name    = "replication-eu-${count.index}"
  ttl     = 300
  type    = "CNAME"
  records = [module.vault_eu[count.index].aws_lb_replication_dns_name]
  zone_id = data.aws_route53_zone.default.id
}

# Add a load balancer record for replication to DNS zone.
resource "aws_route53_record" "replication_us" {
  count   = length(aws_acm_certificate.default_us)
  name    = "replication-us-${count.index}"
  records = [module.vault_us[count.index].aws_lb_replication_dns_name]
  ttl     = 300
  type    = "CNAME"
  zone_id = data.aws_route53_zone.default.id
}

# Add health checking for "eu".
resource "aws_route53_health_check" "eu" {
  count             = length(aws_acm_certificate.default_eu)
  failure_threshold = "3"
  fqdn              = module.vault_eu[count.index].aws_lb_dns_name
  port              = 8200
  request_interval  = "10"
  resource_path     = "/v1/sys/health"
  type              = "HTTPS"
  tags = {
    owner = "Robert de Bock"
    Name  = "vault-eu-${count.index}"
  }
}

# Add health checking for "us".
resource "aws_route53_health_check" "us" {
  count             = length(aws_acm_certificate.default_us)
  failure_threshold = "3"
  fqdn              = module.vault_us[count.index].aws_lb_dns_name
  port              = 8200
  request_interval  = "10"
  resource_path     = "/v1/sys/health"
  type              = "HTTPS"
  tags = {
    owner = "Robert de Bock"
    Name  = "vault-us-${count.index}"
  }
}

# Create a "eu" record.
resource "aws_route53_record" "eu" {
  count           = length(aws_acm_certificate.default_eu)
  health_check_id = aws_route53_health_check.eu[count.index].id
  name            = "vault.eu.meinit.nl"
  records         = [module.vault_eu[count.index].aws_lb_dns_name]
  set_identifier  = count.index == 0 ? "eu-primary" : "eu-secondary"
  ttl             = "60"
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.default.id
  failover_routing_policy {
    type = count.index == 0 ? "PRIMARY" : "SECONDARY"
  }
}

# Create a "us" record.
resource "aws_route53_record" "us" {
  count           = length(aws_acm_certificate.default_us)
  health_check_id = aws_route53_health_check.us[count.index].id
  name            = "vault.us.meinit.nl"
  records         = [module.vault_us[count.index].aws_lb_dns_name]
  set_identifier  = count.index == 0 ? "us-primary" : "us-secondary"
  ttl             = "60"
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.default.id
  failover_routing_policy {
    type = count.index == 0 ? "PRIMARY" : "SECONDARY"
  }
}

# Add "vault.eu" to "vault" for Europe.
resource "aws_route53_record" "eu_endpoint" {
  name           = "vault.meinit.nl"
  records        = ["vault.eu.meinit.nl"]
  set_identifier = "EU Load Balancer"
  ttl            = 60
  type           = "CNAME"
  zone_id        = data.aws_route53_zone.default.zone_id
  geolocation_routing_policy {
    continent = "EU"
  }
}

# Add "vault.us" to "vault" for the rest of the world.
resource "aws_route53_record" "us_endpoint" {
  name           = "vault.meinit.nl"
  records        = ["vault.us.meinit.nl"]
  set_identifier = "US Load Balancer"
  ttl            = 60
  type           = "CNAME"
  zone_id        = data.aws_route53_zone.default.zone_id
  geolocation_routing_policy {
    continent = "NA"
  }
}
