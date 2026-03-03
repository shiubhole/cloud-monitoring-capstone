terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
    }
    time = {
      source = "hashicorp/time"
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
  ami                         = "ami-051a31ab2f4d498f5"
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.grafana_profile.name

  user_data = <<EOF
              #!/bin/bash

dnf update -y

dnf install -y wget curl

cat <<REPO > /etc/yum.repos.d/grafana.repo
[grafana]
name=Grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
REPO

dnf install -y grafana-enterprise
systemctl daemon-reload


systemctl enable grafana-server
systemctl start grafana-server
systemctl stop firewalld || true

sleep 60

systemctl status grafana-server
EOF

  tags = {
    Name = "Grafana-Server"
  }
}

resource "time_sleep" "wait_for_grafana" {
  depends_on = [aws_instance.grafana]
  create_duration = "240s"
}
