module "vpc" {
  source = "./modules/vpc"
}

module "sns" {
  source      = "./modules/sns"
  alert_email = var.alert_email
}

module "ec2" {
  source          = "./modules/ec2"
  instances       = var.instances
  subnet_id       = module.vpc.subnet_id
  security_group  = module.vpc.security_group_id
}

module "cloudwatch" {
  source           = "./modules/cloudwatch"
  instance_map     = module.ec2.instance_map
  sns_topic_arn    = module.sns.topic_arn
}

module "dashboard" {
  source       = "./modules/cloudwatch-dashboard"
  instance_ids = values(module.ec2.instance_map)
}
module "cloudtrail" {
  source = "./modules/cloudtrail"
}

module "config" {
  source = "./modules/config"
}

module "grafana" {
  source         = "./modules/grafana"
  subnet_id      = module.vpc.subnet_id
  security_group = module.vpc.security_group_id
  region         = var.region 
}

module "jenkins" {
  source         = "./modules/jenkins"
  subnet_id      = module.vpc.subnet_id
  security_group = module.vpc.security_group_id
}
