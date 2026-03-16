variable "region" {}

variable "acl_value" {
  type = string
  default = "private"
}

variable "project_name" {
  type = string
  default = "terraform"
}
variable "client_name" {
  type = string
  default = "cdd"
}