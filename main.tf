#######################################
# Data Sources
#######################################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

#######################################
# VPC
#######################################
module "lanchonete_vpc" {
  source     = "./modules/aws/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "lanchonete-vpc"
}

#######################################
# Subnets
# Private Subnets for DB
#######################################
module "lanchonete_db_private_subnet_a" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-db-private-subnet-a"
  availability_zone       = "us-east-1a"
}

module "lanchonete_db_private_subnet_b" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-db-private-subnet-b"
  availability_zone       = "us-east-1b"
}

#######################################
# Private Subnets for EKS
#######################################
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

#######################################
# Public Subnet for NAT Gateway and Internet Access
#######################################
module "public_subnet" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = true
  name                    = "lanchonete-public-subnet"
  availability_zone       = "us-east-1a"
}

#######################################
# Internet Gateway
#######################################
module "internet_gateway" {
  source = "./modules/aws/internet_gateway"
  vpc_id = module.lanchonete_vpc.vpc_id
  name   = "lanchonete-public-igw"
}

#######################################
# NAT Gateway - should be in a Public Subnet
#######################################
module "nat_gateway" {
  source    = "./modules/aws/nat_gateway"
  subnet_id = module.public_subnet.subnet_id
  name      = "lanchonete-nat-gw"
}

#######################################
# Route Tables
#######################################
# Public Route Table
module "lanchonete_public_rt" {
  source = "./modules/aws/route_table"
  vpc_id = module.lanchonete_vpc.vpc_id
  name   = "lanchonete-public-rt"
}

# Private Route Table
module "lanchonete_private_rt" {
  source = "./modules/aws/route_table"
  vpc_id = module.lanchonete_vpc.vpc_id
  name   = "lanchonete-private-rt"
}

#######################################
# Routes
#######################################
# Public route to internet
resource "aws_route" "lanchonete_public_inet_route" {
  route_table_id         = module.lanchonete_public_rt.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.internet_gateway.internet_gateway_id
}

# Private route via NAT Gateway
resource "aws_route" "lanchonete_private_inet_route" {
  route_table_id         = module.lanchonete_private_rt.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.nat_gateway.nat_gateway_id
}

#######################################
# Route Table Associations
#######################################
resource "aws_route_table_association" "lanchonete_private_rta_a" {
  subnet_id      = module.lanchonete_db_private_subnet_a.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}

resource "aws_route_table_association" "lanchonete_private_rta_b" {
  subnet_id      = module.lanchonete_db_private_subnet_b.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}

resource "aws_route_table_association" "lanchonete_public_rta" {
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = module.lanchonete_public_rt.route_table_id
}

resource "aws_route_table_association" "eks_private_rta_a" {
  subnet_id      = module.lanchonete_eks_private_subnet_a.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}

resource "aws_route_table_association" "eks_private_rta_b" {
  subnet_id      = module.lanchonete_eks_private_subnet_b.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}

#######################################
# Security Groups
#######################################
module "lanchonete_rds_sg" {
  source              = "./modules/aws/security_group"
  vpc_id              = module.lanchonete_vpc.vpc_id
  ingress_port        = 5432
  ingress_protocol    = "tcp"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  name                = "lanchonete-rds-sg"
}

#######################################
# Secrets Manager
#######################################
module "db_password_secret" {
  source        = "./modules/aws/secrets_manager_secret"
  name          = "db-password"
  secret_string = "postgres"
  tags = {
    Provisioner = "Terraform"
  }
}

#######################################
# RDS Instance
#######################################
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
  subnet_group_name      = "lanchonete-subnet-group"
  subnet_ids = [
    module.lanchonete_db_private_subnet_a.subnet_id,
    module.lanchonete_db_private_subnet_b.subnet_id
  ]
}

#######################################
# HTTP API Gateway
#######################################
module "lanchonete_http_api" {
  source              = "./modules/aws/http_api_gateway"
  name                = "lanchonete-http-api"
  vpc_link_name       = "lanchonete-vpc-link"
  vpc_link_subnet_ids = [module.lanchonete_eks_private_subnet_a.subnet_id, module.lanchonete_eks_private_subnet_b.subnet_id]
  protocol_type       = "HTTP"
  stage_name          = "$default"
}

#######################################
# EKS Cluster
#######################################
module "lanchonete_eks_cluster" {
  source = "./modules/aws/eks_cluster"

  cluster_name    = "lanchonete-eks-cluster"
  role_arn        = data.aws_iam_role.lab_role.arn
  private_subnets = [module.lanchonete_eks_private_subnet_a.subnet_id, module.lanchonete_eks_private_subnet_b.subnet_id]
}

#######################################
# EKS Node Group
#######################################
module "lanchonete_eks_node_group" {
  source = "./modules/aws/eks_node_group"

  cluster_name    = module.lanchonete_eks_cluster.cluster_name
  node_group_name = "lanchonete-eks-node-group"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = [module.lanchonete_eks_private_subnet_a.subnet_id, module.lanchonete_eks_private_subnet_b.subnet_id]

  tags = {
    Provisioner = "Terraform"
  }
}
