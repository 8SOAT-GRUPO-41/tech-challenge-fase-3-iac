resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.role_arn

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = var.security_group_ids
  }

  access_config {
    authentication_mode = var.authentication_mode
  }
}
