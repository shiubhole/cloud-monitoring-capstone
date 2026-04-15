variable "subnet_id" {}
variable "security_group" {}


resource "aws_iam_role" "jenkins_ssm_role" {
  name = "jenkins-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.jenkins_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.jenkins_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-ssm-profile"
  role = aws_iam_role.jenkins_ssm_role.name
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-015f858f67af9374d"                                                  
  #"ami-051a31ab2f4d498f5"
  instance_type               = "t3.small"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
yum install -y java-21-amazon-corretto

wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

yum install -y jenkins

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins
EOF

  tags = { Name = "Jenkins-Server" }
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [aws_instance.jenkins]
  create_duration = "120s"
}

resource "aws_ssm_association" "install_jenkins" {
  name = "AWS-RunShellScript"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.jenkins.id]
  }

  parameters = {
    commands = join("\n", [
      "echo 'Waiting for Jenkins to be ready...'",
      "until nc -z localhost 8080; do sleep 10; done",
      "echo 'Jenkins is up. Installing plugins...'",

      "cd /tmp",
      "wget https://github.com/jenkinsci/plugin-installation-manager-tool/releases/latest/download/jenkins-plugin-manager.jar",

      "sudo java -jar /tmp/jenkins-plugin-manager.jar --war /usr/share/java/jenkins.war --plugin-download-directory /var/lib/jenkins/plugins --plugins credentials git github-api github workflow-aggregator pipeline-stage-view branch-api scm-api terraform aws-credentials",

      "sudo chown -R jenkins:jenkins /var/lib/jenkins/plugins",
      "sudo systemctl restart jenkins",
      "sudo systemctl status jenkins",
      "sudo netstat -tulnp | grep 8080",
    ])
  }

  depends_on = [time_sleep.wait_120_seconds]
}