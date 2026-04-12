terraform {
  required_providers {
    
    time = {
      source = "hashicorp/time"
    }
  }
}





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

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "grafana_profile" {
  name = "grafana-instance-profile"
  role = aws_iam_role.grafana_role.name
}




resource "aws_instance" "grafana" {
  ami                         = "ami-015f858f67af9374d"
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.grafana_profile.name
  
  tags = {
    Name = "Grafana-Server"
  }
}

resource "aws_ssm_association" "install_grafana" {

  depends_on = [aws_instance.grafana]

  name = "AWS-RunShellScript"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.grafana.id]
  }

  parameters = {
    commands = jsonencode([

      "sudo dnf update -y",

      "sudo dnf install -y wget",

      "cd /tmp",

      "wget https://dl.grafana.com/oss/release/grafana-10.4.2-1.x86_64.rpm",


      "sudo dnf install -y grafana-10.4.2-1.x86_64.rpm",

      "sudo systemctl daemon-reload",

      "sudo systemctl enable grafana-server",

      "sudo systemctl start grafana-server"
    ])
  }
}


resource "time_sleep" "wait_for_grafana" {
  depends_on = [aws_instance.grafana]
  create_duration = "180s"
}
