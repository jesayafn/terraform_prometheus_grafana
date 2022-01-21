#!bin/bash

#Update repositori
sudo apt update
sudo apt upgrade -y

#Installing Node Exporter for Prometheus [Port:9100, Version: v1.3.1]
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz -P /opt
sudo tar -zxf /opt/node_exporter-1.3.1.linux-amd64.tar.gz --one-top-level=/opt/node_exporter-1.3.1 --strip-component=1

#Run Node Exporter for Prometheus as a Service
sudo bash -c 'cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter for Prometheus

[Service]
User=root
ExecStart=/opt/node_exporter-1.3.1/node_exporter

[Install]
WantedBy=default.target
EOF'


#Install Prometheus [Port:9090, Version:v2.32.1]
wget https://github.com/prometheus/prometheus/releases/download/v2.32.1/prometheus-2.32.1.linux-amd64.tar.gz -P /opt
sudo tar -zxf /opt/prometheus-2.32.1.linux-amd64.tar.gz --one-top-level=/opt/prometheus-2.32.1 --strip-component=1

#Configure Prometheus
sudo bash -c 'cat <<EOF > /opt/prometheus-2.32.1/config.yml
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
Description=Prometheus

[Service]
User=root
ExecStart=/opt/prometheus-2.32.1/prometheus --config.file=/opt/prometheus-2.32.1/config.yml --web.external-url=http://10.10.10.10:9090/

[Install]
WantedBy=default.target
EOF'

#Install Grafana Enterprise [Port 3000 Version: v8.3.4]
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-8.3.4.linux-amd64.tar.gz -P /opt
sudo tar -zxf /opt/grafana-enterprise-8.3.4.linux-amd64.tar.gz --one-top-level=/opt/grafana-enterprise-8.3.4 --strip-component=1

#Run Grafana as a Service
sudo bash -c 'cat <<EOF > /etc/systemd/system/grafana.service
[Unit]
Description=Grafana

[Service]
User=root
ExecStart=/opt/grafana-enterprise-8.3.4/bin/grafana-server -homepath /opt/grafana-enterprise-8.3.4/ web

[Install]
WantedBy=default.target
EOF'

#Start Prometheus, Node Exporter for Prometheus, and Grafana Enterprise Service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter.service prometheus.service grafana.service
sudo systemctl start node_exporter.service prometheus.service grafana.service

#Clean-up unnecessary
rm *.tar.gz
