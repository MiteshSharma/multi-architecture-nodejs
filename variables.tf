variable "cloud_service_provider" {
  description = "the name of cloud service provider"
  type        = string
  default     = "aws"
}

variable "service_name" {
  description = "the name of the service"
  type        = string
  default     = "rudderstack-nodejs"
}

variable "architecture_list" {
  description = "the list of architecture name"
  type        = list(string)
  default = [
    "amd64",
    "i386",
    "arm32v8",
    "arm64v8"
  ]
}

variable "region" {
  description = "the default region name"
  type        = string
  default     = "ap-southeast-1"
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