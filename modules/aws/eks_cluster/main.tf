resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.role_arn
  version  = var.version

  vpc_config {
    subnet_ids = var.private_subnets
  }

  depends_on = var.depends_on
}
