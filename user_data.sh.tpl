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
chmod 0750 /vault/data

# 169.254.169.254 is an Amazon service to provide information about itself.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"

# Place the Vault configuration.
cat << EOF > /etc/vault.d/vault.hcl
ui=true

storage "raft" {
  path = "/vault/data"
  node_id = "$${my_hostname}"
  retry_join {
    auto_join               = "provider=aws tag_key=name tag_value=${name}-${random_string} region=${region}"
    auto_join_scheme        = "http"
    # TODO: Maybe creat tls material like this: https://github.com/hashicorp/terraform-aws-vault/blob/master/modules/private-tls-cert/main.tf
    # leader_ca_cert_file     = "/vault/tls/vault.ca"
    # leader_client_cert_file = "/vault/tls/vault.crt"
    # leader_client_key_file  = "/vault/tls/vault.key"
    # TODO: If TLS is enabled, switch to `https`.
  }
  # TODO: check mlock true or not. (https://www.vaultproject.io/docs/configuration/storage/raft)
}

cluster_addr = "http://$${my_ipaddress}:8201"
api_addr = "http://$${my_ipaddress}:8200"

listener "tcp" {
  address            = "$${my_ipaddress}:8200"
  tls_disable        = true
  # tls_client_ca_file = "/vault/tls/vault.ca"
  # tls_cert_file      = "/vault/tls/vault.crt"
  # tls_key_file       = "/vault/tls/vault.key"
  # TODO: Enable TLS; all nodes may have one key & certificate.
}

seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_id}"
}
EOF

# Start and enable Vault.
systemctl --now enable vault

# Allow users to use `vault`.
echo "export VAULT_ADDR=http://$${my_ipaddress}:8200" >> /etc/profile
