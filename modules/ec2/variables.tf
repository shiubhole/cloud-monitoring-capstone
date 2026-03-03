variable "instances" {
  description = "Map of EC2 instances"
  type = map(object({
    instance_type = string
  }))
}

variable "subnet_id" {
  type = string
}

variable "security_group" {
  type = string
}