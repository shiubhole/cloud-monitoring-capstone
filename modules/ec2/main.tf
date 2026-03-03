resource "aws_iam_role" "cw_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cw_profile" {
  name = "ec2-cloudwatch-profile"
  role = aws_iam_role.cw_role.name
}

resource "aws_instance" "app" {
  for_each = var.instances

  ami                         = "ami-051a31ab2f4d498f5"
  instance_type               = each.value.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group]
  iam_instance_profile        = aws_iam_instance_profile.cw_profile.name
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y amazon-cloudwatch-agent
cat <<EOT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "metrics": {
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["used_percent"], "resources": ["*"] }
    }
  }
}
EOT
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
EOF

  tags = {
    Name        = each.key
    Environment = "Production"
    Owner       = "DevOps"
  }
}

output "instance_map" {
  value = {
    for key, instance in aws_instance.app :
    key => instance.id
  }
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}