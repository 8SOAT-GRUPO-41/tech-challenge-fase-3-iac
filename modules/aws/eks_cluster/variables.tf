variable "cluster_name" {
  type = string
}

variable "private_subnets" {
  description = "VPC private subnets"
  type        = list(any)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(any)
}

variable "authentication_mode" {
  description = "The authentication mode for the EKS cluster"
  type        = string
}

variable "role_arn" {
  description = "The ARN of the role that provides permissions for the EKS cluster"
  type        = string
}
