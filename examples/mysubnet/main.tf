# Make a certificate.
resource "aws_acm_certificate" "default" {
  domain_name = "mysubnet.robertdebock.nl"
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
  api_addr             = "https://mysubnet.robertdebock.nl:8200"
  certificate_arn      = aws_acm_certificate.default.arn
  key_filename         = "id_rsa.pub"
  name                 = "msbnt"
  source               = "../../"
  vpc_cidr_block_start = "192.168"
  private_subnet_ids   = ["subnet-0114a1bf19906728f", "subnet-0e245b9df1e54dade", "subnet-0f4c5b9df7227bd2c"]
  public_subnet_ids    = ["subnet-09e2489480140e86a", "subnet-02d0623c59e455eea", "subnet-065a697a451e8b08c"]
  vpc_id               = "vpc-04d8245ad1f1f546c"
  tags = {
    owner = "robertdebock"
  }
}

# Add a loadbalancer record to DNS zone.
resource "cloudflare_record" "default" {
  name    = "mysbt"
  type    = "CNAME"
  value   = module.vault.aws_lb_dns_name
  zone_id = data.cloudflare_zone.default.id
}
