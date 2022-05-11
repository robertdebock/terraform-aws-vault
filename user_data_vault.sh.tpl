#!/bin/bash

# Always update packages installed.
yum update -y

# Add the HashiCorp RPM repository.
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install a specific version of Vault.
yum install -y ${vault_package}

# Allow auto-completion.
vault -autocomplete-install

# Allow IPC lock capability to Vault.
setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

# Disable core dumps.
echo '* hard core 0' >> /etc/security/limits.d/vault.conf
echo '* soft core 0' >> /etc/security/limits.d/vault.conf
ulimit -c 0

# Make a directory for Raft, certificates and init information.
mkdir -p "${vault_path}"
chown vault:vault "${vault_path}"
chmod 750 "${vault_path}"

# 169.254.169.254 is an Amazon service to provide information about itself.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
my_instance_id="$(curl http://169.254.169.254/latest/meta-data/instance-id)"

# Place CA key and certificate.
test -d ${vault_path}/tls || mkdir ${vault_path}/tls
chown vault:vault ${vault_path}/tls
chmod 700 ${vault_path}/tls
echo "${vault_ca_key}" > ${vault_path}/tls/vault_ca.pem
echo "${vault_ca_cert}" > ${vault_path}/tls/vault_ca.crt
chmod 600 ${vault_path}/tls/vault_ca.pem
chmod 600 ${vault_path}/tls/vault_ca.crt

# Place request.cfg.
cat << EOF > ${vault_path}/tls/request.cfg
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
openssl req -config ${vault_path}/tls/request.cfg -new -newkey rsa:2048 -nodes -keyout ${vault_path}/tls/vault.pem -extensions ext -out ${vault_path}/tls/vault.csr
chmod 640 ${vault_path}/tls/vault.pem

# Sign the certificate signing request using the distributed CA.
openssl x509 -extfile ${vault_path}/tls/request.cfg -extensions ext -req -in ${vault_path}/tls/vault.csr -CA ${vault_path}/tls/vault_ca.crt -CAkey ${vault_path}/tls/vault_ca.pem -CAcreateserial -out ${vault_path}/tls/vault.crt -days 7300

# Concatenate CA and server certificate.
cat ${vault_path}/tls/vault_ca.crt >> ${vault_path}/tls/vault.crt

# The TLS material is owned by Vault.
chown vault:vault ${vault_path}/tls/*

# A single "$": passed from Terraform.
# A double "$$": determined in the runtime of this script.

# Place the Vault configuration.
cat << EOF > /etc/vault.d/vault.hcl
cluster_name      = "${name}"
disable_mlock     = true
ui                = ${vault_ui}
api_addr          = "${api_addr}"
cluster_addr      = "https://$${my_ipaddress}:8201"
log_level         = "${log_level}"
max_lease_ttl     = "${max_lease_ttl}"
default_lease_ttl = "${default_lease_ttl}"

storage "raft" {
  path    = "${vault_path}/data"
  node_id = "$${my_instance_id}"
  retry_join {
    auto_join               = "provider=aws tag_key=Name tag_value=${instance_name} addr_type=private_v4 region=${region}"
    auto_join_scheme        = "https"
    leader_ca_cert_file     = "${vault_path}/tls/vault_ca.crt"
    leader_client_cert_file = "${vault_path}/tls/vault.crt"
    leader_client_key_file  = "${vault_path}/tls/vault.pem"
  }
}

listener "tcp" {
  address            = "$${my_ipaddress}:8200"
  cluster_address    = "$${my_ipaddress}:8201"
  tls_key_file       = "${vault_path}/tls/vault.pem"
  tls_cert_file      = "${vault_path}/tls/vault.crt"
  tls_client_ca_file = "${vault_path}/tls/vault_ca.crt"
}

seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_id}"
}
EOF

# Expose the license.
if [ ! -z "${vault_license}" ] ; then
  echo "VAULT_LICENSE=${vault_license}" >> /etc/vault.d/vault.env
fi

# Start and enable Vault.
systemctl --now enable vault

# Allow users to use `vault`.
echo "export VAULT_ADDR=https://$${my_ipaddress}:8200" >> /etc/profile.d/vault.sh
echo "export VAULT_CACERT=${vault_path}/tls/vault_ca.crt" >> /etc/profile.d/vault.sh
