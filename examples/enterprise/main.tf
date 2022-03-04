# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "ent.robertdebock.nl"
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
  allowed_cidr_blocks_replication = ["0.0.0.0/0"]
  api_addr        = "https://ent.robertdebock.nl:8200"
  certificate_arn = aws_acm_certificate.default.arn
  name            = "ntrpr"
  source          = "../../"
  key_filename    = "id_rsa.pub"
  vault_type      = "enterprise"
  vault_license   = "INTENTIONALLY_BROKEN_FQMTMNNEWU33JJVKE2MC2I5HGUT2UJF2E6RDLO5MXSMDXJV5GY2KMKRTTKWLNIV2FSV2GNRHEIQJQLJWU42KPIRRTASLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJWFS3KSNVGVIULYJ5JTAM2NI5DGQTCUNRUU43KVORNFI3DIJ5BTA6SZPJRTGTLKIEZU4MSONVHG2SLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUISLUJVCE4VKNKRKTMTSENM3E4RDHOVGVISL2JZVGO6CNKRKXQV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQLZJRKEC6SWIRCTCT3KKE2U62SRGRLWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJF2E2RCNORGUIVSVJVKFKNSOIRVTMTSENBQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJEXITKEJV2E2RC2KVGVIVJWJZCGWNSOIRUGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZNGQZCXPAYES2LXNFNG26DILIZU22KPNZZWSYSXHFVWIV3YNRRXSSJWK54UU5DEK54DAYKTGFVVS6JRPJMTERTTLJJUS42JNVSHMZDNKZ4WE3KGOVMTEVLUMNDTS43BK5HDKSLJO5UVSV2SGJMVONLKLJLVC5C2I5DDAWKTGF3WG3JZGBNFOTRQMFLTS5KJNQYTSZSRHU6S4RKZKRSEE6CYOYYEQMTLKVKUEMLSOVEUIQZTJF3VCN2NPBUUS3TMOAVWGUKUMNEWYRJVFNJTI5DEKBMUE2CTGJCGQ5LRJNGUM22BKQYDCTLKLJ2UWL3WPFATQRLRGVEXGOCTNFGUCSRRMRAWWY3BGRSFMMBTGM4FA53NKZWGC5SKKA2HASTYJFETSRBWKVDEYVLBKZIGU22XJJ2GGRBWOBQWYNTPJ5TEO3SLGJ5FAS2KKJWUOSCWGNSVU53RIZSSW3ZXNMXXGK2BKRHGQUC2M5JS6S2WLFTS6SZLNRDVA52MG5VEE6CJG5DU6YLLGZKWC2LBJBXWK2ZQKJKG6NZSIRIT2PI"
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "ent"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}
