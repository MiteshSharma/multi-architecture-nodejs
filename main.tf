module "aws-stacks" {
  source = "./modules/aws"
  count  = var.cloud_service_provider == "aws" ? 1 : 0

  service_name                = var.service_name
  architecture_list           = var.architecture_list
  github_credential_token     = var.github_credential_token
  github_credential_user_name = var.github_credential_user_name
  github_repository_url       = var.github_repository_url
}

module "gcp-stacks" {
  source = "./modules/gcp"
  count  = var.cloud_service_provider == "gcp" ? 1 : 0

  service_name      = var.service_name
  architecture_list = var.architecture_list
}