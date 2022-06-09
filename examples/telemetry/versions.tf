terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.9.1"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "1.23.0"
    }
  }
}

provider "grafana" {
  url  = "http://${aws_instance.grafana.public_ip}:3000"
  auth = "admin:Su93rS3cu5e"
}
