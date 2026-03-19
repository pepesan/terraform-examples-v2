terraform {
  required_version = ">= 1.5.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_pet" "app" {
  length = 2

  lifecycle {
    precondition {
      condition     = var.instance_count % length(var.private_subnets) == 0
      error_message = "instance_count debe ser divisible por el número de private_subnets."
    }
  }
}

resource "terraform_data" "app_config" {
  input = {
    app_name        = var.app_name
    instance_count  = var.instance_count
    private_subnets = var.private_subnets
    enable_dns      = var.enable_dns
  }

  lifecycle {
    precondition {
      condition     = var.enable_dns
      error_message = "enable_dns debe ser true."
    }

    postcondition {
      condition     = length(self.output.private_subnets) >= 2
      error_message = "La aplicación requiere al menos 2 private_subnets."
    }
  }
}

check "app_name_reasonable_length" {
  assert {
    condition     = length(var.app_name) >= 3 && length(var.app_name) <= 12
    error_message = "app_name debe tener entre 3 y 12 caracteres."
  }
}