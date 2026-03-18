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

  bucket_name = var.bucket_name

  providers = {
    aws = aws.euw3
  }
}

