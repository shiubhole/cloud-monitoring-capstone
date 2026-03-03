provider "grafana" {
  url  = "http://${aws_instance.grafana.public_ip}:3000"
  auth = "admin:admin"
}



resource "grafana_data_source" "cloudwatch" {
    depends_on = [time_sleep.wait_for_grafana]

    type = "cloudwatch"
    name = "AWS-CloudWatch"

    json_data_encoded = jsonencode({
        authType      = "default"
        defaultRegion = var.region
  })
}



resource "grafana_dashboard" "ec2_dashboard" {
    depends_on = [grafana_data_source.cloudwatch]
    config_json = jsonencode({
        title = "EC2 Monitoring Dashboard"
        panels = [
            {
                type = "timeseries"
                title = "CPU Utilization"
                datasource = "AWS-CloudWatch"
                targets = [{
                    namespace  = "AWS/EC2"
                    metricName = "CPUUtilization"
                    statistic  = "Average"
                }]
            },
            {
                type = "timeseries"
                title = "Memory Usage"
                datasource = "AWS-CloudWatch"
                targets = [{
                    namespace  = "CWAgent"
                    metricName = "mem_used_percent"
                    statistic  = "Average"
                }]
            }
    ]
  })
}