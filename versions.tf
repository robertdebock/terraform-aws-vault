terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.2"
    }
  }
}
