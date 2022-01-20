#!bin/bash

#Update repositori
sudo apt-get update
sudo apt install vi

#Installing Node Exporter [Port:9100, Version: v1.3.1]
cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
cd node_exporter-1.3.1.linux-amd64
./node_exporter

#Run Node Exporter as a Service
sudo bash -c 'cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=root
ExecStart=/opt/node_exporter-1.3.1.linux-amd64/node_exporter

[Install]
WantedBy=default.target
EOF'

#Start Node Exporter Service
sudo systemctl daemon-reload
sudo enable node_exporter.service
sudo start node_exporter.service