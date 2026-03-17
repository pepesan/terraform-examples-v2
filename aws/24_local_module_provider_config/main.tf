terraform {
  required_version = ">= 1.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Configuración alternativa con el alias "euw3".
provider "aws" {
  alias  = "euw3"
  region = "eu-west-3"
}

module "app" {
  source = "./modules/app"

  bucket_name = "mi-app-euw3"

  providers = {
    aws = aws.euw3
  }
}

output "app_bucket_arn" {
  description = "ARN del bucket creado por el módulo app"
  value       = module.app.bucket_arn
}

output "app_bucket_name" {
  description = "Nombre del bucket creado por el módulo app"
  value       = module.app.bucket_name
}