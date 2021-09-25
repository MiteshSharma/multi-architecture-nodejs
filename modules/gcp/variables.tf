variable "service_name" {
  description = "the name of the service"
  type        = string
}

variable "architecture_list" {
  description = "the list of architecture name"
  type        = list(string)
}
