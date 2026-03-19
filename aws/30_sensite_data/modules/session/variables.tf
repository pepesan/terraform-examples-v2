variable "session_token" {
  description = "Token efímero recibido desde el módulo raíz."
  type        = string
  sensitive   = true
  ephemeral   = true
}