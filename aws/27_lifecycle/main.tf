terraform {
  required_version = ">= 1.12.0"
}

variable "app_version" {
  type    = string
  default = "1.0.0"
}

resource "terraform_data" "config" {
  input = {
    app_name = "demo"
    owner    = "equipo-platform"
  }

  lifecycle {
    # Si alguien cambia "input" en el .tf, Terraform no intentará actualizarlo.
    ignore_changes = [input]
  }
}

resource "terraform_data" "deployment" {
  input = {
    version = var.app_version
  }

  # Cuando cambia app_version, este recurso se reemplaza.
  triggers_replace = [
    var.app_version
  ]

  lifecycle {
    # Terraform crea primero la nueva instancia lógica
    # y destruye después la anterior.
    create_before_destroy = true
  }
}

resource "terraform_data" "critical_record" {
  input = "no borrar"

  lifecycle {
    # Impide que Terraform destruya este recurso por accidente.
    prevent_destroy = true
  }
}

output "config_output" {
  value = terraform_data.config.output
}

output "deployment_output" {
  value = terraform_data.deployment.output
}

output "critical_output" {
  value = terraform_data.critical_record.output
}