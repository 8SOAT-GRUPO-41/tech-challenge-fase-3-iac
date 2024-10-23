variable "identifier" {
  description = "RDS identifier"
  type        = string
}

variable "engine" {
  description = "RDS engine (e.g., postgres, mysql)"
  type        = string
}

variable "instance_class" {
  description = "Instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "password" {
  description = "Master password"
  type        = string
}

variable "publicly_accessible" {
  description = "Whether the instance is publicly accessible"
  type        = bool
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "name" {
  description = "Name tag for the RDS instance"
  type        = string
}
