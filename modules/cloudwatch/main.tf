variable "instance_map" { type = map(string) }
variable "sns_topic_arn" {}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  for_each = var.instance_map

  alarm_name          = "CPU-Alarm-${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions = [var.sns_topic_arn]
}