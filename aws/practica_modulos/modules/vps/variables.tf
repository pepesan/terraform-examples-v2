variable "ssh_key_path" {
  type = string
}
variable "ssh_key_private_path" {
  type = string
}
variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "project_name" {
  type    = string
  default = "profe"
}
