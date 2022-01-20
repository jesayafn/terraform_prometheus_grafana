output "public_ip_ec2" {
  value = aws_instance.prometheus.public_ip
}