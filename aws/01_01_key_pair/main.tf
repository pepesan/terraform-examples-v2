provider "aws" {
  region = "eu-west-3"
}

variable "project_name" {
  type = string
  default = "profe"
}

variable "ssh_key_path" {
  type = string
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-ubuntu-${var.project_name}"
  public_key = file(var.ssh_key_path)
}

output "ssh_key_name" {
  value = "Clave creada ${aws_key_pair.deployer.key_name}"
}