terraform {
  required_providers {
    time = {
      source = "hashicorp/time"
    }
  }
}

# Wait until Grafana is fully started
resource "time_sleep" "wait_for_grafana" {
  depends_on = [var.grafana_instance_id]

  create_duration = "180s"
}

# Configure Grafana CloudWatch datasource using API
resource "null_resource" "grafana_datasource" {

  depends_on = [time_sleep.wait_for_grafana]

  provisioner "local-exec" {

    command = <<EOT

GRAFANA_URL="http://${var.grafana_public_ip}:3000"

echo "Creating CloudWatch datasource..."

curl -X POST "$GRAFANA_URL/api/datasources" \
-H "Content-Type: application/json" \
-u admin:admin \
-d '{
"name":"AWS-CloudWatch",
"type":"cloudwatch",
"access":"proxy",
"jsonData":{
"defaultRegion":"${var.region}",
"authType":"default"
}
}'

EOT

  }
}

# Import EC2 dashboard automatically
resource "null_resource" "grafana_dashboard" {

  depends_on = [null_resource.grafana_datasource]

  provisioner "local-exec" {

    command = <<EOT

GRAFANA_URL="http://${var.grafana_public_ip}:3000"

echo "Importing EC2 dashboard..."

curl -X POST "$GRAFANA_URL/api/dashboards/db" \
-H "Content-Type: application/json" \
-u admin:admin \
-d '{
"dashboard":{
"title":"EC2 Monitoring Dashboard",
"panels":[
{
"type":"timeseries",
"title":"CPU Utilization",
"targets":[
{
"namespace":"AWS/EC2",
"metricName":"CPUUtilization",
"statistic":"Average"
}
]
},
{
"type":"timeseries",
"title":"Memory Usage",
"targets":[
{
"namespace":"CWAgent",
"metricName":"mem_used_percent",
"statistic":"Average"
}
]
}
]
},
"overwrite":true
}'

EOT

  }
}