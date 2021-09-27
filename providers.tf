provider "aws" {
  region = var.region == "" ? null : var.region
}

provider "google" {
  project = var.gcp_project_name == "" ? null : var.gcp_project_name
}