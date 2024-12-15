provider "aws" {
  region  = "us-east-1"
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
  name          = "lanchonete-db-password"
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
