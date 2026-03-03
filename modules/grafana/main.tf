terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
    }
  }
}


variable "subnet_id" {}
variable "security_group" {}
variable "region" {}



resource "aws_iam_role" "grafana_role" {
  name = "grafana-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "grafana_cw_attach" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_instance_profile" "grafana_profile" {
  name = "grafana-instance-profile"
  role = aws_iam_role.grafana_role.name
}




resource "aws_instance" "grafana" {
  ami                         = "ami-0f5ee92e2d63afc18"
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.grafana_profile.name

  user_data = <<EOF
#!/bin/bash
yum install -y docker
systemctl start docker

docker run -d -p 3000:3000 \
-e GF_SECURITY_ADMIN_USER=secureadmin \
-e GF_SECURITY_ADMIN_PASSWORD=StrongPassword123 \
-e GF_AUTH_ANONYMOUS_ENABLED=false \
grafana/grafana
EOF

  tags = {
    Name = "Grafana-Server"
  }
}