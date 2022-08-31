provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = "us-east-2"
  alias  = "us-east-2"
}
