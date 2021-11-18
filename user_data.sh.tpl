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

# Place CA key and certificate.
mkdir /etc/vault.d/tls
chown vault:vault /etc/vault.d/tls
chmod 755 /etc/vault.d/tls
echo "${vault_ca_key}" > /etc/vault.d/tls/vault_ca.pem
echo "${vault_ca_cert}" > /etc/vault.d/tls/vault_ca.crt
chmod 640 /etc/vault.d/tls/vault_ca.pem
chmod 644 /etc/vault.d/tls/vault_ca.crt

# Place request.cfg.
cat << EOF > /etc/vault.d/tls/request.cfg
[req]
distinguished_name = dn
req_extensions     = ext
prompt             = no

[dn]
organizationName       = Snake
organizationalUnitName = SnakeUnit
commonName             = vault-internal.cluster.local

[ext]
basicConstraints = CA:FALSE
keyUsage         = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName   = @alt_names

[alt_names]
IP.1 = $${my_ipaddress}
DNS.1 = $${my_hostname}
EOF

# Create a private key and certificate signing request for this instance.
openssl req -config /etc/vault.d/tls/request.cfg -new -newkey rsa:2048 -nodes -keyout /etc/vault.d/tls/vault.pem -extensions ext -out /etc/vault.d/tls/vault.csr
chmod 640 /etc/vault.d/tls/vault.pem

# Sign the certificate signing request using the distributed CA.
openssl x509 -extfile /etc/vault.d/tls/request.cfg -extensions ext -req -in /etc/vault.d/tls/vault.csr -CA /etc/vault.d/tls/vault_ca.crt -CAkey /etc/vault.d/tls/vault_ca.pem -CAcreateserial -out /etc/vault.d/tls/vault.crt -days 7300

# Concatenate CA and server certificate.
cat /etc/vault.d/tls/vault_ca.crt >> /etc/vault.d/tls/vault.crt

# The TLS material is owned by Vault.
chown vault:vault /etc/vault.d/tls/*

# Place the Vault configuration.
cat << EOF > /etc/vault.d/vault.hcl
ui=${vault_ui}

storage "raft" {
  path = "/vault/data"
  node_id = "$${my_hostname}"
  retry_join {
    auto_join               = "provider=aws tag_key=name tag_value=${name}-${random_string} region=${region}"
    auto_join_scheme        = "https"
    leader_ca_cert_file     = "/etc/vault.d/tls/vault_ca.crt"
    leader_client_cert_file = "/etc/vault.d/tls/vault.crt"
    leader_client_key_file  = "/etc/vault.d/tls/vault.pem"
  }
}

cluster_addr = "https://$${my_ipaddress}:8201"
api_addr = "https://$${my_ipaddress}:8200"

listener "tcp" {
  address            = "$${my_ipaddress}:8200"
  tls_key_file       = "/etc/vault.d/tls/vault.pem"
  tls_cert_file      = "/etc/vault.d/tls/vault.crt"
  tls_client_ca_file = "/etc/vault.d/tls/vault_ca.crt"
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
echo "export VAULT_CACERT=/etc/vault.d/tls/vault_ca.crt" >> /etc/profile
