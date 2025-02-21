terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "cdd-profe-backend-tfstate"
    key            = "cdd/terraform.tfstate"
    region         = "eu-west-3"

    # Replace this with your DynamoDB table name!
    # la tabla dynamo ya no es obligatoria pero sí recomendada
    # https://developer.hashicorp.com/terraform/language/backend/s3
    dynamodb_table = "profe-cdd-up-and-running-locks"
    encrypt        = true
  }
}