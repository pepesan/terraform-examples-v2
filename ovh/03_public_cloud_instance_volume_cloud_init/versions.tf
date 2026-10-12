terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh" # provider oficial de OVHcloud en el Terraform Registry
      version = "2.22.0"  # versión fijada para que el ejemplo sea reproducible
    }
  }
  required_version = ">= 1.2.0" # lifecycle/precondition y variable validation
}
