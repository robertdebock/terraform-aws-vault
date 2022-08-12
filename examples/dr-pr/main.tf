# Make a certificate.
resource "aws_acm_certificate" "default" {
  count       = 5
  domain_name = "vault-${count.index}.robertdebock.nl"
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
  count   = length(aws_acm_certificate.default)
  name    = tolist(aws_acm_certificate.default[count.index].domain_validation_options)[0].resource_record_name
  type    = "CNAME"
  value   = regex(".*[^.]", tolist(aws_acm_certificate.default[count.index].domain_validation_options)[0].resource_record_value)
  zone_id = data.cloudflare_zone.default.id
}

# Call the module.
module "vault" {
  count                           = length(aws_acm_certificate.default)
  api_addr                        = "https://vault-${count.index}.robertdebock.nl:8200"
  allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  certificate_arn                 = aws_acm_certificate.default[count.index].arn
  name                            = "vlt-${count.index}"
  instance_type                   = "m6g.medium"
  key_filename                    = "id_rsa.pub"
  size                            = "custom"
  source                          = "../../"
  vault_type                      = "enterprise"
  vault_license                   = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJVKGI2K2KRKTGWSUKF2FS3KNGJNEGMBSLEZE422MK5CTGWKUNN2E26SRGJMWU2DKJZVFM3K2I5HGWSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJEZU2V2KNJHVOULZJ5JTAMSOI5DGSTCUKEYFSVDLORGVOTTILFJTC2CPIRBGSWTNIV3U2V2NPFGWURLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIZ3UJVCEMVKNIRTTMTKEIU3E2VCROVHHUUJTJZVFKNCPKRKTCV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJUJRKEC6CWIRATIT3KIF4E62SFGBLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RDHORGXURSVJVCGONSNIRCTMTKUKJQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKENN2E2RCGKVGUIZZWJVCEKNSNKRJGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S43CMONLFST2TGZYE23CXJRIVUK2OI5VTMT32LF4EGMLGJFZTK53TGBYXIVCNIU3HGT2BJFQW22TFGE3EGOBUKVAUKNCJNRWFQWLKNEXUCYTONUZDOMZUNBHDO3LGF4YWSUZXG5CEG4BRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  vault_replication               = true
  tags = {
    owner = "robertdebock"
  }
}

# Add a load balancer record for the api to DNS zone.
resource "cloudflare_record" "api" {
  count   = length(aws_acm_certificate.default)
  name    = "vault-${count.index}"
  type    = "CNAME"
  value   = module.vault[count.index].aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}

# Add a load balancer record for replication to DNS zone.
resource "cloudflare_record" "replication" {
  count   = length(aws_acm_certificate.default)
  name    = "replication-${count.index}"
  type    = "CNAME"
  value   = module.vault[count.index].aws_lb_replication_dns_name
  zone_id = data.cloudflare_zone.default.id
}
