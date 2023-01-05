# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "watch.${var.domain}"
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
  source                                                = "../../"
  vault_allow_ssh                                       = true
  vault_aws_certificate_arn                             = aws_acm_certificate.default.arn
  vault_enable_telemetry                                = true
  vault_enable_cloudwatch                               = true
  vault_keyfile_path                                    = "id_rsa.pub"
  vault_name                                            = "cldwt"
  vault_enable_telemetry_unauthenticated_metrics_access = false
  vault_type                                            = "enterprise"
  vault_license                                         = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJ5KECMSPI5NGQWKULF2E4VCCNBHEGMBTJZKFS6KMK5NGUTKUKF2E6VCCNJMVOSJQLF5FS522KRVTASLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJEYFUVDDPJHFOSL2LF4TANKPI5CTGTCXJJVU46SJORMWUSJRJZUTC3CNNJRXUTKULJWVUV2FGRNEORLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGVISLUJVVGYVKNIRRTMTKEKE3E4VCROVGXUYZSJVKGOMCNPJCTCV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIRLZJRKESNKWIRATGT3KIEYE62SVPJLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJV2E2RCFORGWU2CVJVCGGNSNIRITMTSUJZQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJGXITKEIV2E22TMKVGUIYZWJVCFCNSOKRHGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S4VKIJJDGQ4KZIZQUW2LKO5BW4ULDOMYGI2SXKU4HCVBPGBRFS2RUGBFXERSVIUZVOUKFO5VUYUCZPBKTQMTKHBSFSYK2JRCVGRSKJB2SWYJZGZNDCMCYKZSHGTLXFN3EQNSEMFVECSRRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_size                                            = "development"
  vault_tags = {
    owner = "Robert de Bock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "aws_route53_record" "default" {
  name    = "watch"
  records = [module.vault.aws_lb_dns_name]
  ttl     = 300
  type    = "CNAME"
  zone_id = data.aws_route53_zone.default.id
}
