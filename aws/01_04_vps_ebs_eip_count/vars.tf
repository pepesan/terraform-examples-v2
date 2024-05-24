variable "ssh_key_path" {
  type = string
}
variable "project_name" {
  type = string
  default = "terraform"
}
variable "region_name" {
  type = string
  default = "eu-west-3"
}
variable "availability_zone" {
  type = string
  default = "eu-west-3a"
}
variable "vpc_id"{
  type = string
}
variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "count_value" {
  type = number
  default = 2
}