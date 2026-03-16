provider "aws" {
  region = var.region
}

variable "region" {
  description = "Región donde se desplegarán los recursos"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "replicas" {
  type    = number
  default = 1
}
# Condicional simple
output "environment_type" {
  value = var.environment == "prod" ? "Producción" : "No producción"
}

# Condición numérica
output "replica_message" {
  value = var.replicas > 1 ? "Sistema distribuido" : "Instancia única"
}

# Condicional encadenado
output "environment_level" {
  value = var.environment == "prod" ? "alto" : var.environment == "staging" ? "medio" : "bajo"
}

# Condicional dentro de una cadena
output "deployment_message" {
  value = "Despliegue en entorno ${var.environment == "prod" ? "crítico" : "de pruebas"}"
}

