variable "vpc_id" {
  type = string
}

variable "project_name" {
  type    = string
  default = "terraform"
}

variable "region_name" {
  type    = string
  default = "eu-west-3"
}

variable "availability_zone" {
  type    = string
  default = "eu-west-3a"
}

variable "ssh_key_path" {
  type = string
}
variable "ssh_key_private_path" {
  type = string
}


variable "environment_name" {
  type    = string
  default = "DEV"
}