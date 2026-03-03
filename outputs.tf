output "ec2_instance_ids" {
  value = module.ec2.instance_map
}

output "dashboard_name" {
  value = module.dashboard.dashboard_name
}
