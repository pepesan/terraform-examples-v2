# Fichero main.tf (Fichero principal del proyecto)
provider "aws" {
  region = "eu-west-3"
}

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

module "llamada" {
  source = "./modules/vps"
  # no hay version porque es local
  ssh_key_path         = var.ssh_key_path
  ssh_key_private_path = var.ssh_key_private_path
  vpc_id               = var.vpc_id
  project_name         = var.project_name
  environment_name     = var.environment_name

}

output "salida-ami-id" {
  value = module.llamada.ami_id
}

output "salida-ip-instance" {
  value = module.llamada.ip_instance
}

output "salida-ssh" {
  value = module.llamada.ssh
}