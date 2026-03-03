variable "alert_email" {}

resource "aws_sns_topic" "alerts" {
  name = "cloud-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "topic_arn" {
  value = aws_sns_topic.alerts.arn
}