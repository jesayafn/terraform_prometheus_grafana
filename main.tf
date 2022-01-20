terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.71.0"
    }
  }
}

provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_accesskey
  secret_key = var.aws_secretkey
}

resource "aws_vpc" "prometheus_grafana" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "prometheus_grafana"
  }
}

resource "aws_subnet" "prometheus_grafana_public" {
  vpc_id                                      = aws_vpc.prometheus_grafana.id
  cidr_block                                  = "10.10.10.0/24"
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "prometheus_grafana"
  }
}

resource "aws_internet_gateway" "prometheus_grafana" {
  vpc_id = aws_vpc.prometheus_grafana.id

  tags = {
    Name = "prometheus_grafana"
  }
}

resource "aws_route_table" "prometheus_grafana_pubsub" {
  vpc_id = aws_vpc.prometheus_grafana.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prometheus_grafana.id
  }

  tags = {
    Name = "prometheus_grafana"
  }
}

resource "aws_route_table_association" "prometheus_grafana_pubsub_routetable" {
  subnet_id      = aws_subnet.prometheus_grafana_public.id
  route_table_id = aws_route_table.prometheus_grafana_pubsub.id
}

resource "aws_security_group" "prometheus_grafana_ec2" {
  vpc_id = aws_vpc.prometheus_grafana.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ping"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "HTTP"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "prometheus_grafana"
  }
}

resource "aws_network_interface" "prometheus_grafana_ec2_eth0" {
  subnet_id       = aws_subnet.prometheus_grafana_public.id
  private_ips     = ["10.10.10.10"]
  security_groups = [aws_security_group.prometheus_grafana_ec2.id]
  tags = {
    Name = "prometheus_grafana_ec2_eth0"
  }
}

resource "aws_instance" "prometheus_grafana" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.prometheus_grafana_ec2_eth0.id
    device_index         = 0
  }

  user_data = file("prometheus_install.sh")
  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "prometheus_grafana"
  }
}