provider "aws" {
  region = "us-east-1"
}

module "lanchonete_vpc" {
  source     = "./modules/aws/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "lanchonete-vpc"
}

module "lanchonete_subnet" {
  source                  = "./modules/aws/subnet"
  vpc_id                  = module.lanchonete_vpc.vpc_id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  name                    = "lanchonete-subnet"
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
  publicly_accessible    = true
  vpc_security_group_ids = [module.lanchonete_rds_sg.security_group_id]
  name                   = "lanchonete-rds"
}
