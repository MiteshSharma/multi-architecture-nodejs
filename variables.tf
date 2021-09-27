variable "cloud_service_provider" {
  description = "Name of cloud service provider"
  type        = string
  default     = "aws"
}

variable "gcp_project_name" {
  description = "Name of GCP project"
  type        = string
  default     = ""
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "crossx-nodejs"
}

variable "region" {
  description = "the default region name"
  type        = string
  default     = ""
}

variable "github_credential_token" {
  description = "the default region name"
  type        = string
}

variable "github_credential_user_name" {
  description = "the default region name"
  type        = string
}

variable "github_repository_url" {
  description = "the default region name"
  type        = string
}