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
  provider    = aws.eu-west-1
  domain_name = "vault-eu-${count.index}.meinit.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "robertdebock"
  }
}

# Make a certificate for US.
resource "aws_acm_certificate" "default_us" {
  count       = 2
  domain_name = "vault-us-${count.index}.meinit.nl"
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
  allow_ssh                       = true
  api_addr                        = "https://vault-eu-${count.index}.meinit.nl:8200"
  aws_kms_key_id                  = data.terraform_remote_state.default.outputs.aws_kms_key_id_eu
  bastion_host                    = count.index == 0 ? true : false
  allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  certificate_arn                 = aws_acm_certificate.default_eu[count.index].arn
  name                            = "veu-${count.index}"
  key_filename                    = "id_rsa.pub"
  size                            = "minimum"
  source                          = "../../"
  vault_type                      = "enterprise"
  vault_license                   = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJVCGY22ONVNGYWKUNN2E22SSNRHFGMLJJZDUS6SMKRATCTTKM52E23KJO5NEIWTLJVDVU22OKRETCSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJWE4VCNGRHHUWJSLJJTC2SZNJGXQTCUNM2E6V2JORNEITJRJVJTC22NK5KTEWLNKF4FSVCGNRGXUWLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIZ3UJVVFUVKNIRVTMTKUMM3E2RCNOVGUIZZRJV5ECNKONJMTCV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJUJRKESMSWIRATKT3KIUZU62SBPJLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RDLORGWUVSVJVCGWNSNKRRTMTKEJZQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKENN2E22S2KVGUI2ZWJVKGGNSNIRHGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S42TMJRXG2QKRMU3XEOLSJ5VDMUCNOBZWSUKENJLEMT2MNN3UO6CRF5BVE3JYJVMFAYKSORRGW3TBJFMHCQKJPFUEE5D2NJ5HSV3DI5RFCZTZJJ2WEQ3WMZIVQ3SUKNIDOYSMIV3UISRRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_replication               = true
  vpc_cidr_block_start            = "10.1"
  private_subnet_ids              = data.terraform_remote_state.default.outputs.private_subnet_ids_eu
  public_subnet_ids               = data.terraform_remote_state.default.outputs.public_subnet_ids_eu
  vpc_id                          = data.terraform_remote_state.default.outputs.vpc_id_eu
  tags = {
    owner = "robertdebock"
  }
}

# Call the module.
module "vault_us" {
  count                           = length(aws_acm_certificate.default_us)
  allow_ssh                       = true
  api_addr                        = "https://vault-us-${count.index}.meinit.nl:8200"
  aws_kms_key_id                  = data.terraform_remote_state.default.outputs.aws_kms_key_id_us
  allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  bastion_host                    = count.index == 0 ? true : false
  certificate_arn                 = aws_acm_certificate.default_us[count.index].arn
  name                            = "vus-${count.index}"
  key_filename                    = "id_rsa.pub"
  size                            = "minimum"
  source                          = "../../"
  vault_type                      = "enterprise"
  vault_license                   = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJVCGY22ONVNGYWKUNN2E22SSNRHFGMLJJZDUS6SMKRATCTTKM52E23KJO5NEIWTLJVDVU22OKRETCSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJWE4VCNGRHHUWJSLJJTC2SZNJGXQTCUNM2E6V2JORNEITJRJVJTC22NK5KTEWLNKF4FSVCGNRGXUWLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIZ3UJVVFUVKNIRVTMTKUMM3E2RCNOVGUIZZRJV5ECNKONJMTCV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJUJRKESMSWIRATKT3KIUZU62SBPJLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RDLORGWUVSVJVCGWNSNKRRTMTKEJZQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKENN2E22S2KVGUI2ZWJVKGGNSNIRHGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S42TMJRXG2QKRMU3XEOLSJ5VDMUCNOBZWSUKENJLEMT2MNN3UO6CRF5BVE3JYJVMFAYKSORRGW3TBJFMHCQKJPFUEE5D2NJ5HSV3DI5RFCZTZJJ2WEQ3WMZIVQ3SUKNIDOYSMIV3UISRRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_replication               = true
  vpc_cidr_block_start            = "10.0"
  private_subnet_ids              = data.terraform_remote_state.default.outputs.private_subnet_ids_us
  public_subnet_ids               = data.terraform_remote_state.default.outputs.public_subnet_ids_us
  vpc_id                          = data.terraform_remote_state.default.outputs.vpc_id_us
  tags = {
    owner = "robertdebock"
  }
}

# Add a load balancer record for the api to DNS zone.
resource "aws_route53_record" "api_eu" {
  count   = length(aws_acm_certificate.default_eu)
  name    = "vault-eu-${count.index}"
  type    = "CNAME"
  ttl     = 300
  records = [module.vault_eu[count.index].aws_lb_dns_name]
  zone_id = data.aws_route53_zone.default.id
}

# Add a load balancer record for the api to DNS zone.
resource "aws_route53_record" "api_us" {
  count   = length(aws_acm_certificate.default_us)
  name    = "vault-us-${count.index}"
  ttl     = 300
  type    = "CNAME"
  records = [module.vault_us[count.index].aws_lb_dns_name]
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
  ttl     = 300
  type    = "CNAME"
  records = [module.vault_us[count.index].aws_lb_replication_dns_name]
  zone_id = data.aws_route53_zone.default.id
}

# Add health checking for "eu".
resource "aws_route53_health_check" "eu" {
  count             = length(aws_acm_certificate.default_eu)
  fqdn              = module.vault_eu[count.index].aws_lb_dns_name
  port              = 8200
  type              = "HTTPS"
  resource_path     = "/v1/sys/health"
  failure_threshold = "3"
  request_interval  = "10"
  tags = {
    owner = "robertdebock"
    Name  = "vault-eu-${count.index}"
  }
}

# Add health checking for "us".
resource "aws_route53_health_check" "us" {
  count             = length(aws_acm_certificate.default_us)
  fqdn              = module.vault_us[count.index].aws_lb_dns_name
  port              = 8200
  type              = "HTTPS"
  resource_path     = "/v1/sys/health"
  failure_threshold = "3"
  request_interval  = "10"
  tags = {
    owner = "robertdebock"
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
  zone_id        = data.aws_route53_zone.default.zone_id
  name           = "vault.meinit.nl"
  ttl            = 60
  type           = "CNAME"
  records        = ["vault.eu.meinit.nl"]
  set_identifier = "EU Load Balancer"
  geolocation_routing_policy {
    continent = "EU"
  }
}

# Add "vault.us" to "vault" for the rest of the world.
resource "aws_route53_record" "us_endpoint" {
  zone_id        = data.aws_route53_zone.default.zone_id
  name           = "vault.meinit.nl"
  ttl            = 60
  type           = "CNAME"
  records        = ["vault.us.meinit.nl"]
  set_identifier = "US Load Balancer"
  geolocation_routing_policy {
    continent = "NA"
  }
}
