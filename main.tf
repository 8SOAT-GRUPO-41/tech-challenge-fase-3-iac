provider "aws" {
  region  = "us-east-1"
  profile = "lab"
}

module "lanchonete_vpc" {
  source     = "./modules/aws/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "lanchonete-vpc"
}

module "lanchonete_subnet_a" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-subnet-a"
  availability_zone       = "us-east-1a"
}

module "lanchonete_subnet_b" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-subnet-b"
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

module "lanchonete_rds" {
  source                 = "./modules/aws/rds"
  identifier             = "lanchonete"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  username               = "postgres"
  password               = "postgres"
  publicly_accessible    = false
  vpc_security_group_ids = [module.lanchonete_rds_sg.security_group_id]
  name                   = "lanchonete-rds"

  subnet_group_name = "lanchonete-subnet-group"
  subnet_ids = [
    module.lanchonete_subnet_a.subnet_id,
    module.lanchonete_subnet_b.subnet_id
  ]
}
