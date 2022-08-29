provider "aws" {
  region = "eu-north-1"
}
provider "cloudflare" {
  api_token = var.cloudflare_token
}