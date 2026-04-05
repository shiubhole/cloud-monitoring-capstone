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

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-ssm-profile"
  role = aws_iam_role.jenkins_ssm_role.name
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-051a31ab2f4d498f5"
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name


  tags = { Name = "Jenkins-Server" }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [aws_instance.jenkins]
  create_duration = "60s"
}

resource "aws_ssm_association" "install_jenkins" {
  name = "AWS-RunShellScript"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.jenkins.id]
  }

  parameters = {
    commands = join("\n", [
      "echo 'Starting Jenkins Installation'",
      "sleep 60",
      "sudo yum update -y",
      "sudo yum install -y java-21-amazon-corretto",
      "java -version",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum install -y jenkins",
      "sudo systemctl daemon-reexec",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "cd /tmp",
      "wget https://github.com/jenkinsci/plugin-installation-manager-tool/releases/latest/download/jenkins-plugin-manager.jar",

      "sudo java -jar /tmp/jenkins-plugin-manager.jar --war /usr/share/java/jenkins.war --plugin-download-directory /var/lib/jenkins/plugins --plugins credentials git github-api github workflow-aggregator pipeline-stage-view branch-api scm-api terraform aws-credentials",

      "sudo chown -R jenkins:jenkins /var/lib/jenkins/plugins",
      "sudo systemctl restart jenkins",
      "sudo systemctl status jenkins",
      "sudo netstat -tulnp | grep 8080",
    ])
  }

  depends_on = [time_sleep.wait_60_seconds]
}