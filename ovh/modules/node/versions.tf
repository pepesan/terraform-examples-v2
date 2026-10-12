# Un módulo debe declarar el provider que usa: sin esto Terraform buscaría
# hashicorp/ovh. La versión exacta la fija el ejemplo que llama al módulo
# (su versions.tf); aquí solo se indica el mínimo.
terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = ">= 2.22.0"
    }
  }
  required_version = ">= 1.2.0" # lifecycle/precondition y variable validation
}
