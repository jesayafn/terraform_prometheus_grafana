#!bin/bash

#Update repositori
sudo apt-get update
sudo apt install vi

#Installing Node Exporter for Prometheus [Port:9100, Version: v1.3.1]
cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
cd /opt/node_exporter-1.3.1.linux-amd64

#Run Node Exporter for Prometheus as a Service
sudo bash -c 'cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter for Prometheus

[Service]
User=root
ExecStart=/opt/node_exporter-1.3.1.linux-amd64/node_exporter

[Install]
WantedBy=default.target
EOF'

#Start Node Exporter for Prometheus Service
sudo systemctl daemon-reload
sudo enable node_exporter.service
sudo start node_exporter.service

#Install Prometheus [Port:9090, Version:v2.32.1]
cd /opt
wget https://github.com/prometheus/prometheus/releases/download/v2.32.1/prometheus-2.32.1.linux-amd64.tar.gz
tar xvfz prometheus-2.32.1.linux-amd64.tar.gz
cd /opt/prometheus-2.32.1.linux-amd64

#Configure Prometheus
sudo bash -c 'cat <<EOF > /opt/prometheus-2.32.1.linux-amd64/config.yml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  scrape_timeout: 5s

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093
          
# Load rules once and periodically evaluate them according to the global "evaluation_interval".
#rule_files:
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["10.10.10.10:9090"]
  - job_name: "node-ec2"
    static_configs:
      - targets: ["10.10.10.10:9100"]
EOF'

#Run Prometheus as a Service
sudo bash -c 'cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Node Exporter

[Service]
User=root
ExecStart=/opt/prometheus-2.32.1.linux-amd64/prometheus --config.file=/opt/prometheus-2.32.1.linux-amd64/config.yml --web.external-url=http://10.10.10.10:9090/

[Install]
WantedBy=default.target
EOF'

#Start Prometheus Service
sudo systemctl daemon-reload
sudo enable prometheus.service
sudo start prometheus.service