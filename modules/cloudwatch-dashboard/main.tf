variable "instance_ids" { type = list(string) }

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "EC2-Monitoring-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title   = "CPU Utilization"
          metrics = [for id in var.instance_ids :
            ["AWS/EC2","CPUUtilization","InstanceId",id]]
          period  = 60
          stat    = "Average"
          region  = "ap-south-1"
        }
      }
    ]
  })
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}