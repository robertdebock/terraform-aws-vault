#!/bin/sh

# Add a repository for Grafana.
cat << EOF >> /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Install Grafana
yum install -y grafana-9.0.9-1.aarch64

# Start Grafana
sudo systemctl enable --now grafana-server

# Set the admin password.
grafana-cli admin reset-admin-password Su93rS3cu5e
