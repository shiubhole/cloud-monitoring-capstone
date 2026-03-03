variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "instances" {
  description = "Map of EC2 instances"
  type = map(object({
    instance_type = string
  }))
}

variable "alert_email" {
    description = "Email for SNS alerts"
}