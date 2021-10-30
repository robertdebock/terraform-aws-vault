# Call the cluster module.
module "vault" {
  source                       = "../../"
  launch_configuration_version = 1
  size                         = "development"
  tags = {
    owner    = "robertdebock"
  }
}

# Recovery Key 1: OGKP27MvVcaKqfUQOtWA0gHOGrxjYp0VvaSAOW/K3B86
# Recovery Key 2: YJgEcKuIEv1b54vPbjVmdPu/emJza1vOMGyLWa27oxwv
# Recovery Key 3: wt6eXL7WyUfJjJ6q2PAxprP7wLQeJrKhjVf0Ie/DTba0
# Recovery Key 4: F0pH6LVzUWRYbtn/9jh1ZbTKjDlMvuC8tKqNMd84XHc8
# Recovery Key 5: rODeFAZvWEeYOHI2vpqFDtRfqOc8bc1W/BMa+WX073MS
#
# Initial Root Token: s.UvODGMru6KKMCqT0TTAu4mV1
