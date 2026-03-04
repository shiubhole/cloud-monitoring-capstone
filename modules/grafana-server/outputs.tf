output "grafana_instance_id" {
  description = "Grafana EC2 Instance ID"
  value       = aws_instance.grafana.id
}

output "public_ip" {
  description = "Public IP of Grafana EC2 instance"
  value       = aws_instance.grafana.public_ip
}