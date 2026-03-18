# Fichero main.tf (Fichero principal del proyecto)
provider "aws" {
  region = "eu-west-3"
}

variable "mivar" {

}

module "llamada" {
  source="./modules/mimodulo"
  mivar = var.mivar
  
}

output "salida-main" {
  value =module.llamada.salida
}