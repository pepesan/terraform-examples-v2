variable "app_name" {
  description = "Nombre lógico de la aplicación."
  type        = string
  default     = "demoapp"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app_name))
    error_message = "app_name solo puede contener minúsculas, números y guiones."
  }
}

variable "instance_count" {
  description = "Número de instancias simuladas."
  type        = number
  default     = 4

  validation {
    condition     = var.instance_count >= 2
    error_message = "instance_count debe ser al menos 2."
  }
}

variable "private_subnets" {
  description = "Lista simulada de subnets privadas."
  type        = list(string)
  default     = ["subnet-a", "subnet-b"]

  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "Debes definir al menos 2 private_subnets."
  }
}

variable "enable_dns" {
  description = "Simula si la red tiene DNS activado."
  type        = bool
  default     = true
}