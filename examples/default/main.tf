# Call the cluster module.
module "vault" {
  source                       = "../../"
  launch_configuration_version = 1
  size                         = "development"
  tags = {
    owner    = "robertdebock"
  }
}
