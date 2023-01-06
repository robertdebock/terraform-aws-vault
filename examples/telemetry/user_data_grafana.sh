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

# Install Grafana, retry a few times, as the instance may need to wait for internet access.

# Set the maximum number of retries
max_retries=5

# Set the initial number of retries to 0
num_retries=0

# Set the interval between retries (in seconds)
retry_interval=30

# Run the command in a loop until it succeeds or the maximum number of retries is reached
until yum install -y grafana-9.0.9-1 ; do
  # Increment the number of retries
  num_retries=$((num_retries+1))

  # Check if the maximum number of retries has been reached
  if [ "$num_retries" -ge "$max_retries" ]; then
    # If the maximum number of retries has been reached, exit the loop and print an error message
    echo "Error: The command failed after $max_retries attempts."
    exit 1
  fi

  # Sleep for the specified interval before retrying the command
  sleep "$retry_interval"
done

# Start Grafana
sudo systemctl enable --now grafana-server

# Set the admin password.
grafana-cli admin reset-admin-password Su93rS3cu5e
