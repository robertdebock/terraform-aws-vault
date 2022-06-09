#!/bin/bash

# Always update packages installed.
yum update -y

# Add the HashiCorp RPM repository.
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install a specific version of Vault.
yum install -y ${vault_package}

# Allow auto-completion for the ec2-user.
runuser -l ec2-user -c "vault -autocomplete-install"

# Allow users to use `vault`.
echo "export VAULT_ADDR=${api_addr}" >> /etc/profile.d/vault.sh
# The common name in the certificate is not known to the instance.
echo "export VAULT_SKIP_VERIFY=1" >> /etc/profile.d/vault.sh
