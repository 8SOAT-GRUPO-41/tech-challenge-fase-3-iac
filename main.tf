provider "google" {
  project = var.project_id
  region  = var.region
}


module "cloud_sql" {
  source = "./modules/gcp/cloud_sql"

  project_id            = var.project_id
  region                = var.region
  default_database_name = var.default_database_name
}
