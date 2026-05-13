variable "project_name" {
  type    = string
  default = "cdd"
}
variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "ssh_key_path" {
  type = string
}
variable "vpc_id" {
  type = string
}