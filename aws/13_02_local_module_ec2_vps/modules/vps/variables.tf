variable "ssh_key_path" {
  type = string
}
variable "ssh_key_private_path" {
  type = string
}
variable "vpc_id" {
  type = string
}

variable "project_name" {
  type    = string
  default = "profe"
}

variable "environment_name" {
  type    = string
  default = "DEV"
}