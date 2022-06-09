# Make a certificate for custer one.
resource "aws_acm_certificate" "one" {
  domain_name = "one.robertdebock.nl"
  # After a deployment, this value (`domain_name`) can't be changed because the certificate is bound to the load balancer listener.
  validation_method = "DNS"
  tags = {
    owner = "robertdebock"
  }
}

# Make a certificate for custer two.
resource "aws_acm_certificate" "two" {
  domain_name = "two.robertdebock.nl"
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

# Add validation details to the DNS zone for certificate one.
resource "cloudflare_record" "validation_one" {
  name    = tolist(aws_acm_certificate.one.domain_validation_options)[0].resource_record_name
  type    = "CNAME"
  value   = regex(".*[^.]", tolist(aws_acm_certificate.one.domain_validation_options)[0].resource_record_value)
  zone_id = data.cloudflare_zone.default.id
}

# Add validation details to the DNS zone for certificate two.
resource "cloudflare_record" "validation_two" {
  name    = tolist(aws_acm_certificate.two.domain_validation_options)[0].resource_record_name
  type    = "CNAME"
  value   = regex(".*[^.]", tolist(aws_acm_certificate.two.domain_validation_options)[0].resource_record_value)
  zone_id = data.cloudflare_zone.default.id
}

# Call the module for cluster one.
module "vault_one" {
  allowed_cidr_blocks_replication          = ["0.0.0.0/0"]
  api_addr                                 = "https://one.robertdebock.nl:8200"
  aws_kms_key_id                           = "0150a897-8bbc-4b91-9d2d-92d4fc47ddb5"
  certificate_arn                          = aws_acm_certificate.one.arn
  instance_type                            = "m6g.medium"
  key_filename                             = "id_rsa.pub"
  name                                     = "one"
  size                                     = "custom"
  source                                   = "../../"
  vault_type                               = "enterprise"
  vault_license                            = "OBFUSCATED_BY_DESIGNWFQMTMNNEWU33JJVWVKMSZK5FGYTSEJV2E6V2WNVNGSMLJJVWUM3CMK5MXQTTNKV2FS2SRO5HVIRTKJVDUM2CNPJVTESLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJE2E2R2RGFMTETTKJVJTA52NNJTXUTCUNRWU4RCBORNFOVTNJVUTC2CPIRWGYTTKIV3VUV2NGBHFIRLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIVLUJVVGIVKNKRATMTKEKU3E4VCNOVGXUVL2J5KFS6CNIRTTIV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJRJRKESM2WIRCXOT3KIEYU62SVPJLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RCZORGWUWSVJVKECNSNIRKTMTSUJZQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKELF2E22TEKVGVIQJWJVCFKNSOKRHGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S4SCCNZSDGU2GKZ2EC52JJ4VW2URLJYYEKQLHGVQVA6JTOJUHUVKLJJVHE3ZTNNSWK3SOOUXUWMDSJFUWIUKTOUVVU2SGINXFU5ZTGRGUEQKBGAZFURLPI5BTGV2EOB5HA5CSKRTEISRRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_replication                        = true
  tags = {
    owner = "robertdebock"
  }
}

# Call the module for cluster two.
module "vault_two" {
  allowed_cidr_blocks_replication          = ["0.0.0.0/0"]
  api_addr                                 = "https://two.robertdebock.nl:8200"
  aws_kms_key_id                           = "0150a897-8bbc-4b91-9d2d-92d4fc47ddb5"
  certificate_arn                          = aws_acm_certificate.two.arn
  name                                     = "two"
  instance_type                            = "m6g.medium"
  key_filename                             = "id_rsa.pub"
  size                                     = "custom"
  source                                   = "../../"
  vault_type                               = "enterprise"
  vault_license                            = "OBFUSCATED_BY_DESIGNWFQMTMNNEWU33JJVWVKMSZK5FGYTSEJV2E6V2WNVNGSMLJJVWUM3CMK5MXQTTNKV2FS2SRO5HVIRTKJVDUM2CNPJVTESLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJE2E2R2RGFMTETTKJVJTA52NNJTXUTCUNRWU4RCBORNFOVTNJVUTC2CPIRWGYTTKIV3VUV2NGBHFIRLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIVLUJVVGIVKNKRATMTKEKU3E4VCNOVGXUVL2J5KFS6CNIRTTIV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJRJRKESM2WIRCXOT3KIEYU62SVPJLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RCZORGWUWSVJVKECNSNIRKTMTSUJZQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKELF2E22TEKVGVIQJWJVCFKNSOKRHGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S4SCCNZSDGU2GKZ2EC52JJ4VW2URLJYYEKQLHGVQVA6JTOJUHUVKLJJVHE3ZTNNSWK3SOOUXUWMDSJFUWIUKTOUVVU2SGINXFU5ZTGRGUEQKBGAZFURLPI5BTGV2EOB5HA5CSKRTEISRRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_replication                        = true
  tags = {
    owner = "robertdebock"
  }
}

# Add a load balancer record to DNS zone for cluster one.
resource "cloudflare_record" "one" {
  name    = "one"
  type    = "CNAME"
  value   = module.vault_one.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Add a load balancer record to DNS zone for cluster two.
resource "cloudflare_record" "two" {
  name    = "two"
  type    = "CNAME"
  value   = module.vault_two.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Add a load balancer record to DNS zone for cluster one.
resource "cloudflare_record" "replication_one" {
  name    = "replication-one"
  type    = "CNAME"
  value   = module.vault_one.aws_lb_replication_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Add a load balancer record to DNS zone for cluster two.
resource "cloudflare_record" "replication_two" {
  name    = "replication-two"
  type    = "CNAME"
  value   = module.vault_two.aws_lb_replication_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Create a (fake) route53 zone.
resource "aws_route53_zone" "default" {
  name = "voorbeeld.com"
}

# Add health checking for "one".
resource "aws_route53_health_check" "one" {
  fqdn              = module.vault_one.aws_lb_dns_name
  port              = 8200
  type              = "HTTPS"
  resource_path     = "/v1/sys/health?performancestandbycode=200"
  failure_threshold = "3"
  request_interval  = "10"
  tags = {
    owner = "robertdebock"
    Name  = "vault-one"
  }
}

# Add health checking for "two".
resource "aws_route53_health_check" "two" {
  fqdn = module.vault_two.aws_lb_dns_name
  port = 8200
  type = "HTTPS"
  # Raft followers will return status 473, performance standby.
  # Becasue we consider both leaders and followers healthy on the load
  # balancer, we need Vault to return 200 for followers.
  # Vault itself will redirect traffic from followers to a leader.
  # "473": Raft standby nodes should be considered healthy.
  # See https://www.vaultproject.io/api-docs/system/health
  resource_path     = "/v1/sys/health?performancestandbycode=200"
  failure_threshold = "3"
  request_interval  = "10"
  tags = {
    owner = "robertdebock"
    Name  = "vault-two"
  }
}
# Create a "one" record in the fake zone.
resource "aws_route53_record" "one" {
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.one.id
  name            = "vault.voorbeeld.com"
  records         = [module.vault_one.aws_lb_dns_name]
  set_identifier  = "one"
  ttl             = "60"
  type            = "CNAME"
  zone_id         = aws_route53_zone.default.id
}

# Create a "two" record in the fake zone.
resource "aws_route53_record" "two" {
  failover_routing_policy {
    type = "SECONDARY"
  }
  health_check_id = aws_route53_health_check.two.id
  name            = "vault.voorbeeld.com"
  records         = [module.vault_two.aws_lb_dns_name]
  set_identifier  = "two"
  ttl             = "60"
  type            = "CNAME"
  zone_id         = aws_route53_zone.default.id
}
