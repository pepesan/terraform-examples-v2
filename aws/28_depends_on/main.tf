terraform {
  required_version = ">= 1.4.0"
}

# 1) Recurso base: simula una "base de datos"
resource "terraform_data" "database" {
  input = {
    name = "app-db"
  }
}

# 2) Dependencia implícita:
# este recurso usa un valor del recurso anterior, así que Terraform
# sabe automáticamente que debe crear database antes que backend
resource "terraform_data" "backend" {
  input = {
    database_name = terraform_data.database.output.name
    app_name      = "backend-api"
  }
}

# 3) Recurso independiente:
# no referencia a nadie, así que Terraform puede crearlo en paralelo
resource "terraform_data" "logging" {
  input = {
    target = "app-logs"
  }
}

# 4) Dependencia explícita:
# este recurso NO usa atributos de logging ni backend en input,
# pero queremos que espere a que ambos existan.
# Eso modela una dependencia "real" que Terraform no puede inferir solo.
resource "terraform_data" "smoke_tests" {
  input = {
    name = "post-deploy-tests"
  }

  depends_on = [
    terraform_data.backend,
    terraform_data.logging
  ]
}

# 5) Dependencia explícita en un módulo local:
# el módulo no usa directamente backend ni smoke_tests en sus variables,
# pero queremos que se ejecute después.
module "report" {
  source = "./modules/report"

  report_name = "deployment-report"

  depends_on = [
    terraform_data.backend,
    terraform_data.smoke_tests
  ]
}

output "database_output" {
  value = terraform_data.database.output
}

output "backend_output" {
  value = terraform_data.backend.output
}

output "logging_output" {
  value = terraform_data.logging.output
}

output "smoke_tests_output" {
  value = terraform_data.smoke_tests.output
}

output "report_output" {
  value = module.report.report_output
}