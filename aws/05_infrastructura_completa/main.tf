# Backends variables and configuration
terraform {
  backend "s3" {
    bucket                  = "informe-nube-tf-states"
    key                     = "terraform.tfstate"
    encrypt                 = "true"
    region                  = "eu-west-1"
    profile                 = "nombredemiyperfil"
    shared_credentials_file = "ruta/a/credentciales/de/aws"
  }
}

# Provider Configuration
provider "aws" {
  region                  = "eu-west-1"
  profile                 = "nombredemiyperfil"
  shared_credentials_file = "ruta/a/credentciales/de/aws"
}
