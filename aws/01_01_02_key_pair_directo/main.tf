provider "aws" {
  region = "eu-west-3"
}

variable "project_name" {
  type    = string
  default = "profe"
}

variable "ssh_public_key" {
  type = string
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-ubuntu-${var.project_name}-test"
  public_key = var.ssh_public_key
}

resource "aws_key_pair" "deployer2" {
  key_name   = "deployer-key-ubuntu-david-test"
  public_key = var.ssh_public_key
}

output "ssh_key_name" {
  value = "Clave creada ${aws_key_pair.deployer.key_name}"
}

output "ssh_arn" {
  value = "ARN creado ${aws_key_pair.deployer.arn}"
}

output "ssh_key_name2" {
  value = "Clave creada ${aws_key_pair.deployer2.key_name}"
}

output "ssh_arn2" {
  value = "ARN creado ${aws_key_pair.deployer2.arn}"
}