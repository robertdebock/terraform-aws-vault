#!/bin/bash

# Always update packages installed.
yum update -y

# Add the HashiCorp RPM repository.
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install a specific version of Vault.
yum install -y ${vault_package}

# Install Apache Benchmark.
yum install -y httpd

# Allow auto-completion for the ec2-user.
runuser -l ec2-user -c "vault -autocomplete-install"

# Allow users to use `vault`.
echo "export VAULT_ADDR=${api_addr}" >> /etc/profile.d/vault.sh
# The common name in the certificate is not known to the instance.
echo "export VAULT_SKIP_VERIFY=1" >> /etc/profile.d/vault.sh

# Set the history to ignore all commands that start with vault.
echo "export HISTIGNORE=\"&:vault*\"" >> /etc/profile.d/vault.sh

# Run a custom, user-provided script.
if [ "${vault_bastion_custom_script_s3_url}" != "" ] ; then
  aws s3 cp "${vault_bastion_custom_script_s3_url}" /custom.sh
  sh /custom.sh
fi
