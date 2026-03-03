variable "subnet_id" {}
variable "security_group" {}

resource "aws_instance" "jenkins" {
  ami                         = "ami-051a31ab2f4d498f5"
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group]
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
yum install -y java-17-amazon-corretto
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins
systemctl start jenkins
EOF

  tags = { Name = "Jenkins-Server" }
}