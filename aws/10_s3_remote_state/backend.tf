terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "cdd-terraform-backend-tfstate"
    # Reemplaza con el nombre del prefijo que quieres para este proyecto
    # coloca el nombre de tu proyecto-alumno
    key    = "cdd/terraform-profe.tfstate"
    region = "eu-west-3"

    use_lockfile = true
    encrypt      = true
  }
}