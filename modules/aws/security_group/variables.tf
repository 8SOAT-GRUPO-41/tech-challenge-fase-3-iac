variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ingress_port" {
  description = "Ingress port"
  type        = number
}

variable "ingress_protocol" {
  description = "Ingress protocol"
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks for ingress"
  type        = list(string)
}

variable "name" {
  description = "Name tag for the security group"
  type        = string
}
