variable "db_password" {
  description = "Password de base de datos. Se oculta en la salida, pero Terraform puede seguir guardándolo en state."
  type        = string
  sensitive   = true
}

variable "session_token" {
  description = "Token temporal de sesión. No se guarda en state ni en plan."
  type        = string
  sensitive   = true
  ephemeral   = true
}