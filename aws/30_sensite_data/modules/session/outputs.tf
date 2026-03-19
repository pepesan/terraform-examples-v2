output "session_token" {
  description = "Se devuelve como output efímero del módulo hijo."
  value       = local.token_copy
  sensitive   = true
  ephemeral   = true
}

output "token_preview" {
  description = "Solo mostramos una derivación no sensible para demostrar uso sin exponer el secreto."
  value       = "token-length-${length(local.token_copy)}"
  sensitive   = true
  ephemeral   = true
}