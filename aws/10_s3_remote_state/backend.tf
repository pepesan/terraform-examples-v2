terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "cdd-terraform-backend-tfstate"
    key            = "cdd/terraform.tfstate"
    region         = "eu-west-3"

    use_lockfile = true
    encrypt      = true
  }
}