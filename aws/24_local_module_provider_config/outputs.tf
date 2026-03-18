output "app_bucket_arn" {
  description = "ARN del bucket creado por el módulo app"
  value       = module.app.bucket_arn
}

output "app_bucket_name" {
  description = "Nombre del bucket creado por el módulo app"
  value       = module.app.bucket_name
}