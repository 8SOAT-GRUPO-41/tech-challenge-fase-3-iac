terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
  }

  required_version = ">= 1.1.0"

  cloud {
    organization = "FIAP-Lanchonete-G41"

    workspaces {
      name = "tech-challenge-fase-3-iac"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
