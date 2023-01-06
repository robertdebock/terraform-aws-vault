provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
}

