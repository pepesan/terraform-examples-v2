# Fichero main.tf (Fichero principal del proyecto)
provider "aws" {
  region = "eu-west-3"
}

module "llamada" {
  source="./modules/mimodulo"
  mivar = "Entrada"
  
}

output "salida-main" {
  value =module.llamada.salida
}