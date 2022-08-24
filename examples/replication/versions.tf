terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.27.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.22.0"
    }
  }
}
