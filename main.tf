#######################################
# Data Sources
#######################################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_lb" "eks_nlb" {
  name = var.eks_nlb_name
}

data "aws_lb_listener" "eks_listener" {
  load_balancer_arn = data.aws_lb.eks_nlb.arn
  port              = 80
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
#######################################

# Private Subnet for DB
module "lanchonete_db_private_subnet_a" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.101.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-db-private-subnet-a"
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "lanchonete-db-private-subnet-a"
  }
}

module "lanchonete_db_private_subnet_b" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.102.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-db-private-subnet-b"
  availability_zone       = "us-east-1b"

  tags = {
    "Name" = "lanchonete-db-private-subnet-b"
  }
}

# Private Subnet for EKS
module "lanchonete_eks_private_subnet_a" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-eks-private-subnet-a"
  availability_zone       = "us-east-1a"

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "Name"                            = "lanchonete-eks-private-subnet-a"
  }
}

module "lanchonete_eks_private_subnet_b" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-eks-private-subnet-b"
  availability_zone       = "us-east-1b"

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "Name"                            = "lanchonete-eks-private-subnet-b"
  }
}

# Public Subnet for NAT Gateway and Internet Access
module "lanchonete_public_subnet_a" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = true
  name                    = "lanchonete-public-subnet-a"
  availability_zone       = "us-east-1a"
  tags = {
    "kubernetes.io/role/elb" = "1"
    "Name"                   = "lanchonete-public-subnet-a"
  }
}
# Public Subnet for NAT Gateway and Internet Access
module "lanchonete_public_subnet_b" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = true
  name                    = "lanchonete-public-subnet-b"
  availability_zone       = "us-east-1b"
  tags = {
    "kubernetes.io/role/elb" = "1"
    "Name"                   = "lanchonete-public-subnet-b"
  }
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
# NAT Gateway - in Public Subnet
#######################################
module "nat_gateway" {
  source    = "./modules/aws/nat_gateway"
  subnet_id = module.lanchonete_public_subnet_a.subnet_id
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

# Private Route Table (for both DB and EKS)
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
# Associate DB subnet with private RT
resource "aws_route_table_association" "lanchonete_private_rta_db_a" {
  subnet_id      = module.lanchonete_db_private_subnet_a.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}

resource "aws_route_table_association" "lanchonete_private_rtb_db_b" {
  subnet_id      = module.lanchonete_db_private_subnet_b.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}


# Associate EKS subnet with private RT
resource "aws_route_table_association" "eks_private_rta" {
  subnet_id      = module.lanchonete_eks_private_subnet_a.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}

resource "aws_route_table_association" "eks_private_rtb" {
  subnet_id      = module.lanchonete_eks_private_subnet_b.subnet_id
  route_table_id = module.lanchonete_private_rt.route_table_id
}

# Associate Public subnet with public RT
resource "aws_route_table_association" "lanchonete_public_rta" {
  subnet_id      = module.lanchonete_public_subnet_a.subnet_id
  route_table_id = module.lanchonete_public_rt.route_table_id
}

resource "aws_route_table_association" "lanchonete_public_rtb" {
  subnet_id      = module.lanchonete_public_subnet_b.subnet_id
  route_table_id = module.lanchonete_public_rt.route_table_id
}

#######################################
# Secrets Manager
#######################################
# module "db_password_secret" {
#   source        = "./modules/aws/secrets_manager_secret"
#   name          = "lanchonete-db-pwd"
#   secret_string = "postgres"
#   tags = {
#     Provisioner = "Terraform"
#   }
# }

#######################################
# HTTP API Gateway
#######################################
module "lanchonete_http_api" {
  source              = "./modules/aws/http_api_gateway"
  name                = "lanchonete-http-api"
  vpc_link_name       = "lanchonete-vpc-link"
  vpc_link_subnet_ids = [module.lanchonete_eks_private_subnet_a.subnet_id]
  protocol_type       = "HTTP"
  stage_name          = "$default"

  tags = {
    Name        = "lanchonete-http-api"
    Provisioner = "Terraform"
  }
}

#######################################
# EKS Cluster
#######################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.1.0"

  cluster_name    = "lanchonete-g41-cluster"
  cluster_version = "1.31"

  create_iam_role = false
  iam_role_arn    = data.aws_iam_role.lab_role.arn
  enable_irsa     = false

  vpc_id = module.lanchonete_vpc.vpc_id

  subnet_ids = [
    module.lanchonete_eks_private_subnet_a.subnet_id,
    module.lanchonete_eks_private_subnet_b.subnet_id
  ]
  control_plane_subnet_ids = [
    module.lanchonete_eks_private_subnet_a.subnet_id,
    module.lanchonete_eks_private_subnet_b.subnet_id
  ]

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    labs = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1

      create_iam_role = false
      iam_role_arn    = data.aws_iam_role.lab_role.arn
    }
  }

  tags = {
    Provisioner = "Terraform"
  }
}
