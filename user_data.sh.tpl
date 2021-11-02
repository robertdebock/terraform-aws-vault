#!/bin/bash

# Always update packages installed.
yum update -y

# Add the HashiCorp RPM repository.
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install a specific version of Vault.
yum install -y vault-${vault_version}

# Allow IPC lock capability to Vault.
setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

# Make a directory for Raft, certificates and init information.
mkdir -p /vault/data
chown vault:vault /vault/data
chmod 750 /vault/data

# 169.254.169.254 is an Amazon service to provide information about itself.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"

# Place TLS material
mkdir /etc/vault.d/tls
chown vault:vault /etc/vault.d/tls
echo "${tls_ca}" > /etc/vault.d/tls/vault.ca
echo "${tls_cert}" > /etc/vault.d/tls/vault.crt
echo "${tls_key}" > /etc/vault.d/tls/vault.key
chown vault:vault /etc/vault.d/tls/*
chmod 750 /etc/vault.d/tls
chmod 640 /etc/vault.d/tls/*


# Place the Vault configuration.
cat << EOF > /etc/vault.d/vault.hcl
ui=true

storage "raft" {
  path = "/vault/data"
  node_id = "$${my_hostname}"
  retry_join {
    auto_join               = "provider=aws tag_key=name tag_value=${name}-${random_string} region=${region}"
    auto_join_scheme        = "https"
    # TODO: Maybe create tls material like this: https://github.com/hashicorp/terraform-aws-vault/blob/master/modules/private-tls-cert/main.tf
    leader_ca_cert_file     = "/etc/vault.d/tls/vault.ca"
    leader_client_cert_file = "/etc/vault.d/tls/vault.crt"
    leader_client_key_file  = "/etc/vault.d/tls/vault.key"
  }
}

cluster_addr = "https://$${my_ipaddress}:8201"
api_addr = "https://$${my_ipaddress}:8200"

listener "tcp" {
  address            = "$${my_ipaddress}:8200"
  tls_client_ca_file = "/etc/vault.d/tls/vault.ca"
  tls_cert_file      = "/etc/vault.d/tls/vault.crt"
  tls_key_file       = "/etc/vault.d/tls/vault.key"
}

seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_id}"
}
EOF

# Start and enable Vault.
systemctl --now enable vault

# Allow users to use `vault`.
echo "export VAULT_ADDR=https://$${my_ipaddress}:8200" >> /etc/profile
