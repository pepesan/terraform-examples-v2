provider "aws" {
  region = "eu-west-3"
}

module "vps" {
  source               = "./modules/vps"
  ssh_key_path         = var.ssh_key_path
  ssh_key_private_path = var.ssh_key_private_path
  vpc_id               = var.vpc_id
  project_name         = var.project_name
}