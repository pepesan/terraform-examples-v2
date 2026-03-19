terraform {
  required_version = ">= 1.10.0"
}

locals {
  db_user = "app_user"
}

module "session" {
  source = "./modules/session"

  session_token = var.session_token
}