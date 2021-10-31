# Call the cluster module.
module "vault" {
  source                       = "../../"
  launch_configuration_version = 1
  size                         = "development"
  tags = {
    owner    = "robertdebock"
  }
}

# Recovery Key 1: I1u103yGctZ0bBN6V9qHSvdb5sRl2H+VA3eZWJKk8uLd
# Recovery Key 2: teePy3qd2b6lG+GUQy6HcVvHlieHLbqPZuvdibKVpvCw
# Recovery Key 3: 3nWytCTVKLmPsv0tioMTO+ztJfvYEgGdDKmhqDOuU8qI
# Recovery Key 4: pSoqE51+KcXBuMIqWx3xk6DTeflRuy34PoWH05LiboBF
# Recovery Key 5: ec6Dicvv1r3akcEjdc7TFbJqbQks2TEqVlVTJZNBx4ao
#
# Initial Root Token: s.J5bRa5XxFkb7KpymaajMsPsy
