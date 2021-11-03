# Call the module.
module "vault" {
  source = "../../"
  size   = "development"
  tags = {
    owner = "robertdebock"
  }
}
