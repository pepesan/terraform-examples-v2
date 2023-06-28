
variable "name" {
  default = ""
}
variable "team" {
  default = ""
}
resource "random_id" "id" {
  byte_length = 8
}

locals {
  name  = (var.name != "" ? var.name : random_id.id.hex)
  owner = var.team
  common_tags = {
    Owner = local.owner
    Name  = local.name
  }
}

output "nombre" {
  value = local.name
}

variable "high_availability" {
  type        = bool
  description = "If this is a multiple instance deployment, choose `true` to deploy 3 instances"
  default     = true
}

output "salida-cond" {
  value = (var.high_availability == true ? 3 : 1)
}

provider "aws" {
  region = "eu-west-3"
}