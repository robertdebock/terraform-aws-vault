# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "autoss.robertdebock.nl"
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
  certificate_arn               = aws_acm_certificate.default.arn
  name                          = "autos"
  source                        = "../../"
  key_filename                  = "id_rsa.pub"
  vault_aws_s3_snapshots_bucket = "vault-snapshots-dggkjg"
  vault_type                    = "enterprise"
  vault_license                 = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JLFLUS6S2NVKTKWSUNN2E6V2JPJGXSMLKJUZFKM2MKRUGSWSEM52E4RCBO5NGUSJVLJDVKMKZKRNGSSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJF4E2R2RGVMXUVTMJZUTAMSOKRCTCTCUIEYFS6SBORMTEVLXJVBTC22PIRKTCTKEIE2VS2SNO5GUORLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIY3UJVCEMVKNIRITMTL2LE3E4VCJOVGUIY3XJZVGOM2NIRGTKV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJTJRKEC6CWIRATAT3KJUZE62SVPBLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RDDORGXURSVJVCFCNSNPJMTMTSUIZQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKEM52E2RCGKVGUIUJWJV5FSNSOKRDGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S4WS2IV4UKR3WNBFWU2ZXLE3FKUDBO4VW43CVMZKFA5CSKVUGCQTJOJWFGQRZHBBFUYLTHF5EUZ2DGZDXUVSMIRYXEMKPOZCWYVJXIV5DSZ3JNRKUESDOIZKEGL2JJB5FOT2QIIYUINJRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "autoss"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}
