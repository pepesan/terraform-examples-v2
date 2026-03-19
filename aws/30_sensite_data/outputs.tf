output "db_username" {
  value = local.db_user
}

output "db_password_sensitive" {
  value     = var.db_password
  sensitive = true
}

output "db_connection_string_masked" {
  value     = "postgres://${local.db_user}:${var.db_password}@db.internal:5432/app"
  sensitive = true
}
