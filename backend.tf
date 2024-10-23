terraform {
  backend "s3" {
    bucket = "lanchonete-terraform-state"
    key    = "lanchonete/terraform.tfstate"
    region = "us-east-1"
  }
}
