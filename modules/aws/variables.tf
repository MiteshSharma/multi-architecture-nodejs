variable "service_name" {
  description = "the name of the service"
  type        = string
}

variable "architecture_list" {
  description = "the list of architecture name"
  type        = list(string)
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