#!/bin/sh

# Install prometheus
useradd --no-create-home --shell /bin/false prometheus
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /var/lib/prometheus
cd /tmp/
wget https://github.com/prometheus/prometheus/releases/download/v2.35.0/prometheus-2.35.0.linux-armv7.tar.gz
tar -xvf prometheus-2.35.0.linux-armv7.tar.gz
cd prometheus-2.35.0.linux-armv7
mv console* /etc/prometheus
mv prometheus /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus

# Place a token.
echo "${credenial}" > /etc/prometheus/prometheus-vault-token

# Write the Prometheus configuration.
cat << EOF >> /etc/prometheus/prometheus.yml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label 'job=<job_name>'' to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
  - job_name: vault
    metrics_path: /v1/sys/metrics
    params:
      format: ['prometheus']
    scheme: https
    authorization:
      credentials_file: /etc/prometheus/prometheus-vault-token
    static_configs:
    - targets: ["${target}:8200"]
EOF

# Change ownership for all Prometheus file.
sudo chown -R prometheus:prometheus /etc/prometheus

# Create a Prometheus service
cat << EOF >> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOF

# Reload sysctl because a new service was added.
sudo systemctl daemon-reload

# Start and enable Prometheus.
sudo systemctl enable --now prometheus

# sudo firewall-cmd --add-service=prometheus --permanent
# sudo firewall-cmd --reload
