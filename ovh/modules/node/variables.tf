# Entradas del módulo node: una máquina de Public Cloud con nginx y su
# registro DNS. El provider y las credenciales los configura quien lo llama.

variable "project_id" {
  type        = string
  description = "Identificador del proyecto Public Cloud (el service_name de la API)"
}

variable "region" {
  type        = string
  description = "Región donde se crea la instancia (p. ej. GRA11)"
}

# Sirve a la vez de nombre de instancia y de subdominio DNS
variable "name" {
  type        = string
  description = "Nombre del nodo: nombre de la instancia y subdominio DNS (<name>.<domain>)"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "name debe ser un nombre DNS válido: minúsculas, números y guiones, sin empezar ni acabar en guion (máx. 63 caracteres)."
  }
}

variable "domain" {
  type        = string
  description = "Zona DNS ya existente en la cuenta de OVH donde se crea el registro"
}

variable "ssh_key_name" {
  type        = string
  description = "Nombre de una clave SSH que ya exista en el proyecto (la crea quien llama al módulo)"
}

variable "flavor_name" {
  type        = string
  description = "Nombre exacto del flavor (p. ej. c3-16)"
}

variable "image_name" {
  type        = string
  description = "Nombre exacto de la imagen (p. ej. Ubuntu 26.04)"
}

variable "backup_enabled" {
  type        = bool
  description = "Activa el backup automático (auto_backup); cambiarlo recrea la instancia"
  default     = false
}

variable "backup_cron" {
  type        = string
  description = "Cuándo se hace el backup automático, en formato cron Unix"
  default     = "0 3 * * *"
}

variable "backup_rotation" {
  type        = number
  description = "Cuántos backups automáticos se conservan"
  default     = 7

  validation {
    condition     = var.backup_rotation >= 1
    error_message = "backup_rotation debe ser al menos 1."
  }
}

variable "dns_ttl" {
  type        = number
  description = "Segundos que los resolvers pueden cachear el registro A"
  default     = 3600
}
