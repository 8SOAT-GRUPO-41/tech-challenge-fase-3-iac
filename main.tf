data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

module "lanchonete_vpc" {
  source     = "./modules/aws/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "lanchonete-vpc"
}

module "lanchonete_db_private_subnet_a" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-private-subnet-a"
  availability_zone       = "us-east-1a"
}

module "lanchonete_db_private_subnet_b" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-private-subnet-b"
  availability_zone       = "us-east-1b"
}

module "lanchonete_eks_private_subnet_a" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-eks-private-subnet-a"
  availability_zone       = "us-east-1a"
}

module "lanchonete_eks_private_subnet_b" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-eks-private-subnet-b"
  availability_zone       = "us-east-1b"
}

module "lanchonete_rds_sg" {
  source              = "./modules/aws/security_group"
  vpc_id              = module.lanchonete_vpc.vpc_id
  ingress_port        = 5432
  ingress_protocol    = "tcp"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  name                = "lanchonete-rds-sg"
}

module "db_password_secret" {
  source        = "./modules/aws/secrets_manager_secret"
  name          = "db-password"
  secret_string = "postgres"
  tags = {
    Provisioner = "Terraform"
  }
}

module "lanchonete_rds" {
  source                 = "./modules/aws/rds"
  identifier             = "lanchonete"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  username               = "postgres"
  password               = module.db_password_secret.secret_id
  publicly_accessible    = false
  vpc_security_group_ids = [module.lanchonete_rds_sg.security_group_id]
  name                   = "lanchonete-rds"

  subnet_group_name = "lanchonete-subnet-group"
  subnet_ids = [
    module.lanchonete_db_private_subnet_a.subnet_id,
    module.lanchonete_db_private_subnet_b.subnet_id
  ]
}

module "lanchonete_http_api" {
  source = "./modules/aws/http_api_gateway"

  name          = "lanchonete-http-api"
  vpc_link_name = "lanchonete-vpc-link"
  protocol_type = "HTTP"
  stage_name    = "$default"
}

module "lanchonete_eks_cluster" {
  source = "./modules/aws/eks_cluster"

  cluster_name = "lanchonete-eks-cluster"
  role_arn     = data.aws_iam_role.lab_role.arn
  private_subnets = [
    module.lanchonete_eks_private_subnet_a.subnet_id,
    module.lanchonete_eks_private_subnet_b.subnet_id
  ]
  security_group_ids  = [module.lanchonete_rds_sg.security_group_id]
  authentication_mode = "API_AND_CONFIG_MAP"
}

module "lanchonete_eks_node_group" {
  source = "./modules/aws/eks_node_group"

  cluster_name    = module.lanchonete_eks_cluster.cluster_name
  node_group_name = "lanchonete-eks-node-group"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids = [
    module.lanchonete_eks_private_subnet_a.subnet_id,
    module.lanchonete_eks_private_subnet_b.subnet_id
  ]
  tags = {
    Provisioner = "Terraform"
  }
}

# resource "aws_apigatewayv2_integration" "eks_integration" {
#   api_id                 = module.lanchonete_http_api.api_id
#   integration_type       = "HTTP_PROXY"
#   connection_type        = "VPC_LINK"
#   connection_id          = module.lanchonete_http_api.vpc_link_id
#   # integration_uri        = data.aws_lb.eks_service_lb.arn
#   integration_method     = "GET"
#   payload_format_version = "2.0"
# }
