variable "vpc_id" {
  type        = string
  description = "ID directo de la VPC (estrategia 1)"
}

variable "vpc_name" {
  type        = string
  description = "Tag Name de la VPC (estrategias 2 y 3)"
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