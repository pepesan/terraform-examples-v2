terraform {
  required_providers {
    contabo = {
      source = "contabo/contabo"
      version = ">= 0.1.32"
    }
  }
}

variable "contabo_client_id" {
  type = string
}

variable "contabo_client_secret" {
  type = string
}

variable "contabo_user" {
  type = string
}

variable "contabo_pass" {
  type = string
}

# carga el .env con las variables de entorno
# source .env
provider "contabo" {
  oauth2_client_id     = var.contabo_client_id
  oauth2_client_secret = var.contabo_client_secret
  oauth2_user          = var.contabo_user
  oauth2_pass          = var.contabo_pass
}
