variable "availability_zone_a" {
  default = "eu-west-3a"
}
variable "availability_zone_b" {
  default = "eu-west-3b"
}
variable "availability_zone_c" {
  default = "eu-west-3c"
}
variable "db_password" {
  default = "admin1234"
}

variable "project_name" {
  type = string
  default = "terraform"
}

variable "subnet_group_name" {
  type = string
}