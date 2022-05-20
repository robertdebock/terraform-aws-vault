provider "aws" {
  # You can set your AWS credentials in environment variables:
  # ```shell
  # export AWS_ACCESS_KEY_ID=AKIA123ABC
  # export AWS_SECRET_ACCESS_KEY=123ABC
  # ```
  region = var.region
}
