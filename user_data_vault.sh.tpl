#!/bin/bash

# Always update packages installed.
yum update -y

# Make a directory for Raft, certificates and init information.
mkdir -p "${vault_path}"
mkfs.ext4 /dev/sda1
mount /dev/sda1 "${vault_path}"
chmod 750 "${vault_path}"

# Make a directory for audit logs.
if [ "${audit_device}" = "true" ] ; then
  mkdir -p "${audit_device_path}"
  mkfs.ext4 /dev/sdb
  mount /dev/sdb "${audit_device_path}"
  chmod 750 "${audit_device_path}"
fi

# Install the AWS Cloudwatch agent
if [ "${cloudwatch}" = "true" ] ; then
  yum install -y amazon-cloudwatch-agent
fi

# Add the HashiCorp RPM repository.
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install a specific version of Vault.
yum install -y "${vault_package}"

# Change ownership for the `vault_path``.
chown vault:vault "${vault_path}"

# Optionally change ownership for `audit_device_path`.
if [ -d "${audit_device_path}" ] ; then
  chown vault:vault "${audit_device_path}"
fi

# Allow auto-completion for the ec2-user.
runuser -l ec2-user -c "vault -autocomplete-install"

# Allow IPC lock capability to Vault.
setcap cap_ipc_lock=+ep "$(readlink -f "$(which vault)")"

# Disable core dumps.
echo '* hard core 0' >> /etc/security/limits.d/vault.conf
echo '* soft core 0' >> /etc/security/limits.d/vault.conf
ulimit -c 0

# 169.254.169.254 is an Amazon service to provide information about itself.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
my_instance_id="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
my_region="$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d\" -f4)"

# Place CA key and certificate.
test -d "${vault_path}/tls" || mkdir "${vault_path}/tls"
chmod 0755 "${vault_path}/tls"
chown vault:vault "${vault_path}/tls"
echo "${vault_ca_key}" > "${vault_path}/tls/vault_ca.pem"
echo "${vault_ca_cert}" > "${vault_path}/tls/vault_ca.crt"
chmod 0600 "${vault_path}/tls/vault_ca.pem"
chown root:root "${vault_path}/tls/vault_ca.pem"
chmod 0644 "${vault_path}/tls/vault_ca.crt"
chown root:root "${vault_path}/tls/vault_ca.crt"

# Place request.cfg.
cat << EOF > "${vault_path}/tls/request.cfg"
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
openssl req -config "${vault_path}/tls/request.cfg" -new -newkey rsa:2048 -nodes -keyout "${vault_path}/tls/vault.pem" -extensions ext -out "${vault_path}/tls/vault.csr"
chmod 0640 "${vault_path}/tls/vault.pem"
chown root:vault "${vault_path}/tls/vault.pem"

# Sign the certificate signing request using the distributed CA.
openssl x509 -extfile "${vault_path}/tls/request.cfg" -extensions ext -req -in "${vault_path}/tls/vault.csr" -CA "${vault_path}/tls/vault_ca.crt" -CAkey "${vault_path}/tls/vault_ca.pem" -CAcreateserial -out "${vault_path}/tls/vault.crt" -days 7300
chmod 0644 "${vault_path}/tls/vault.crt"
chown root:root "${vault_path}/tls/vault.crt"

# Concatenate CA and server certificate.
cat "${vault_path}/tls/vault_ca.crt" >> "${vault_path}/tls/vault.crt"

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
  address                        = "$${my_ipaddress}:8200"
  cluster_address                = "$${my_ipaddress}:8201"
  tls_key_file                   = "${vault_path}/tls/vault.pem"
  tls_cert_file                  = "${vault_path}/tls/vault.crt"
  tls_client_ca_file             = "${vault_path}/tls/vault_ca.crt"
  telemetry {
    unauthenticated_metrics_access = ${unauthenticated_metrics_access}
  }
}

seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_id}"
}
EOF

if [ "${telemetry}" = true ] ; then
cat << EOF >> /etc/vault.d/vault.hcl

telemetry {
  prometheus_retention_time      = "${prometheus_retention_time}"
  disable_hostname               = ${prometheus_disable_hostname}
}
EOF
fi

# Expose the license.
if [ -n "${vault_license}" ] ; then
  echo "VAULT_LICENSE=${vault_license}" >> /etc/vault.d/vault.env
fi

# Start and enable Vault.
systemctl --now enable vault

# Setup logrotate if the audit_device is enabled.
if [ "${audit_device}" = "true" ] ; then
  cat << EOF > /etc/logrotate.d/vault
${audit_device_path}/*.log {
  rotate $[${audit_device_size}*4]
  missingok
  compress
  size 512M
  postrotate
    /usr/bin/systemctl reload vault 2> /dev/null || true
  endscript
}
EOF
fi

# Run logrotate hourly.
cp /etc/cron.daily/logrotate /etc/cron.hourly/logrotate

# Allow users to use `vault`.
echo "export VAULT_ADDR=https://$${my_ipaddress}:8200" >> /etc/profile.d/vault.sh
echo "export VAULT_CACERT=${vault_path}/tls/vault_ca.crt" >> /etc/profile.d/vault.sh

# Set the history to ignore all commands that start with vault.
echo "export HISTIGNORE=\"&:vault*\"" >> /etc/profile.d/vault.sh

# Allow ec2-user access to Vault files.
usermod -G vault ec2-user

# Place an AWS EC2 health check script.
cat << EOF >> /usr/local/bin/aws_health.sh
#!/bin/sh

# This script checks that status of Vault and reports that status to the ASG.
# If vault fails, the instance is replaced.

# Tell vault how to connect.
export VAULT_ADDR=https://$${my_ipaddress}:8200
export VAULT_CACERT="${vault_path}/tls/vault_ca.crt"

# Get the status of Vault and report to AWS ASG.
if vault status > /dev/null 2>&1 ; then
  aws --region $${my_region} autoscaling set-instance-health --instance-id $${my_instance_id} --health-status Healthy
else
  aws --region $${my_region} autoscaling set-instance-health --instance-id $${my_instance_id} --health-status Unhealthy
fi
EOF

# Make the AWS EC2 health check script executable.
chmod 754 /usr/local/bin/aws_health.sh

# Run the AWS EC2 health check every minute, 5 minutes after provisioning.
sleep "${warmup}" && crontab -l | { cat; echo "* * * * * /usr/local/bin/aws_health.sh"; } | crontab -

# Place a script to discover if this instance is terminated.
cat << EOF >> /usr/local/bin/aws_deregister.sh
#!/bin/sh

# If an instance is terminated, de-register the instance from the target group.
# This means no traffic is sent to the node that is being terminated.
# After this deregistration, it's safe to destroy the instance.

if (curl --silent http://169.254.169.254/latest/meta-data/autoscaling/target-lifecycle-state | grep Terminated) ; then
%{ for target_group_arn in target_group_arns }
  deregister-targets --target-group-arn "${target_group_arn}" --targets $${my_instance_id}
%{ endfor }
fi
EOF

# Make the AWS Target Group script executable.
chmod 754 /usr/local/bin/aws_deregister.sh

crontab -l | { cat; echo "* * * * * /usr/local/bin/aws_deregister.sh"; } | crontab -
